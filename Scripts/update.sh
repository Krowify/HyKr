#!/usr/bin/env bash
# Full system update for a live HyKr install, in one command:
#
#   1. Pull this repo (rebase, autostash) -- refuses to touch a clone that is
#      stuck mid-merge/mid-rebase instead of piling a second operation on it.
#   2. Upgrade every package (yay -Syu: repo + AUR), then install anything
#      pkg_core.lst gained since this machine was set up.
#   3. Update flatpaks, if flatpak is installed.
#   4. Rebuild hyprpm plugins when Hyprland itself was upgraded -- plugins are
#      built against one Hyprland's headers and refuse to load on another.
#   5. Copy repo config changes into ~/.config (sync_configs.sh --apply).
#   6. Re-apply the current theme, but only when the pull changed the theme
#      switcher -- re-applying unconditionally would throw away a wallpaper
#      picked since (and its pywal border) on every update.
#   7. Report what still needs a human: .pacnew files, orphans, a reboot.
#
# Usage: ~/HyKr/Scripts/update.sh [--yes] [--skip-repo] [--skip-system]
#   --yes          don't stop at yay's/flatpak's confirmation prompts
#   --skip-repo    leave the HyKr checkout alone (no pull, no config sync)
#   --skip-system  dotfiles only: no yay, flatpak or hyprpm

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

# Every step below handles its own failure and carries on; a summary at the
# end lists what didn't work. set -e (from global_fn.sh) would instead stop
# a package upgrade halfway because, say, one flatpak remote was down.
set +e

ASSUME_YES=0
SKIP_REPO=0
SKIP_SYSTEM=0
# Internal: set when this script re-execs itself after a pull changed it.
RESUME_FROM=""

usage() {
    cat <<'USAGE'
Usage: update.sh [--yes] [--skip-repo] [--skip-system]
  --yes          don't stop at yay's/flatpak's confirmation prompts
  --skip-repo    leave the HyKr checkout alone (no pull, no config sync)
  --skip-system  dotfiles only: no yay, flatpak or hyprpm
USAGE
}

orig_args=("$@")
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y | --yes) ASSUME_YES=1 ;;
        --skip-repo) SKIP_REPO=1 ;;
        --skip-system) SKIP_SYSTEM=1 ;;
        --resume-from)
            RESUME_FROM="$2"
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

failed_steps=()
section() { echo; print_log "==> $*"; }

if [[ ${EUID} -eq 0 ]]; then
    print_log "Run this as your normal user, not root -- yay refuses to build AUR packages as root,"
    print_log "and the config steps write into your home directory. It asks for sudo itself."
    exit 1
fi

command -v pacman &>/dev/null || {
    print_log "pacman not found -- this targets Arch Linux."
    exit 1
}

# --------------------------------------------------- // 1. HyKr repo
repo_changed_files=""
# Cleared when the checkout is stuck mid-merge/rebase: syncing configs out of
# a tree like that can copy conflict markers straight into ~/.config.
repo_usable=1

if [[ -n "${RESUME_FROM}" ]]; then
    # Second pass after a re-exec: the pull already happened in the first.
    repo_changed_files="$(git -C "${repoDir}" diff --name-only "${RESUME_FROM}" HEAD 2>/dev/null)"
elif [[ ${SKIP_REPO} -eq 0 ]]; then
    section "Updating the HyKr repo (${repoDir})"

    git_dir="$(git -C "${repoDir}" rev-parse --absolute-git-dir 2>/dev/null)"
    branch="$(git -C "${repoDir}" symbolic-ref -q --short HEAD 2>/dev/null)"
    upstream="$(git -C "${repoDir}" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"

    repo_blocker=""
    if [[ -z "${git_dir}" ]]; then
        repo_blocker="${repoDir} is not a git checkout"
    elif [[ -d "${git_dir}/rebase-merge" || -d "${git_dir}/rebase-apply" ]]; then
        repo_blocker="a rebase is in progress -- finish it (git rebase --continue) or drop it (git rebase --abort)"
    elif [[ -f "${git_dir}/MERGE_HEAD" ]]; then
        repo_blocker="a merge is in progress -- finish it (git commit) or drop it (git merge --abort)"
    elif [[ -n "$(git -C "${repoDir}" diff --name-only --diff-filter=U 2>/dev/null)" ]]; then
        repo_blocker="there are unresolved conflicts (see: git status)"
    elif [[ -z "${branch}" ]]; then
        repo_blocker="HEAD is detached -- check out a branch first (git switch main)"
    elif [[ -z "${upstream}" ]]; then
        repo_blocker="branch '${branch}' tracks no remote branch (git branch -u origin/main)"
    fi

    if [[ -n "${repo_blocker}" ]]; then
        print_log "Skipping the repo update: ${repo_blocker}."
        print_log "  cd ${repoDir} to sort it out, then re-run this script."
        print_log "  Config sync and theme re-apply are skipped until then."
        repo_usable=0
        failed_steps+=("repo update (${repo_blocker%% -- *})")
    else
        old_head="$(git -C "${repoDir}" rev-parse HEAD)"
        # --autostash: local edits to tracked files (a tweaked .zshrc, nvim's
        # lazy-lock.json) are set aside for the pull and put back after it,
        # rather than making the pull refuse outright.
        if git -C "${repoDir}" pull --rebase --autostash; then
            new_head="$(git -C "${repoDir}" rev-parse HEAD)"
            if [[ "${old_head}" == "${new_head}" ]]; then
                print_log "Already up to date."
            else
                git -C "${repoDir}" log --oneline "${old_head}..${new_head}"
                repo_changed_files="$(git -C "${repoDir}" diff --name-only "${old_head}" "${new_head}")"

                # The pull may have changed this very script. Finish with the
                # new version rather than the old one already in memory.
                if grep -qx 'Scripts/update.sh' <<<"${repo_changed_files}"; then
                    print_log "update.sh itself changed -- continuing with the new version."
                    exec "${repoDir}/Scripts/update.sh" "${orig_args[@]}" --resume-from "${old_head}"
                fi
            fi
        else
            # A failed `pull --rebase` leaves the rebase open. Abort it so the
            # clone is back exactly where it was (autostash is restored too)
            # instead of leaving it half-rebased for the next run to trip on.
            if [[ -d "${git_dir}/rebase-merge" || -d "${git_dir}/rebase-apply" ]]; then
                git -C "${repoDir}" rebase --abort
            fi
            print_log "git pull failed -- the repo is unchanged. Run it by hand to see why:"
            print_log "  git -C ${repoDir} pull --rebase --autostash"
            failed_steps+=("repo update (git pull)")
        fi
    fi
fi

# --------------------------------------------------- // 2. Packages
hypr_before="$(pacman -Q hyprland 2>/dev/null)"

if [[ ${SKIP_SYSTEM} -eq 0 ]]; then
    section "Upgrading packages"

    confirm_flag=()
    [[ ${ASSUME_YES} -eq 1 ]] && confirm_flag=(--noconfirm)

    if command -v yay &>/dev/null; then
        yay -Syu "${confirm_flag[@]}" || failed_steps+=("package upgrade (yay -Syu)")
    else
        print_log "yay not found -- upgrading repo packages only (AUR packages are skipped)."
        sudo pacman -Syu "${confirm_flag[@]}" || failed_steps+=("package upgrade (pacman -Syu)")
    fi

    # Packages pkg_core.lst gained after this machine was installed. Done as
    # a separate step, after the upgrade, so one renamed or vanished package
    # in the list can't abort the whole system upgrade with it. `pacman -T`
    # prints only what isn't satisfied, and understands `provides`.
    mapfile -t core_pkgs < <(grep -vE '^\s*#|^\s*$' "${scrDir}/pkg_core.lst" | awk '{print $1}')
    mapfile -t missing_pkgs < <(pacman -T "${core_pkgs[@]}" 2>/dev/null)
    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        print_log "New core packages to install: ${missing_pkgs[*]}"
        if command -v yay &>/dev/null; then
            yay -S --needed "${confirm_flag[@]}" "${missing_pkgs[@]}" ||
                failed_steps+=("new core packages (${missing_pkgs[*]})")
        else
            sudo pacman -S --needed "${confirm_flag[@]}" "${missing_pkgs[@]}" ||
                failed_steps+=("new core packages (${missing_pkgs[*]})")
        fi
    fi

    # --------------------------------------------------- // 3. Flatpak
    if command -v flatpak &>/dev/null; then
        section "Updating flatpaks"
        flatpak_flag=()
        [[ ${ASSUME_YES} -eq 1 ]] && flatpak_flag=(-y)
        flatpak update "${flatpak_flag[@]}" || failed_steps+=("flatpak update")
    fi

    # --------------------------------------------------- // 4. hyprpm plugins
    # hyprexpo/hyprgrass (extra/setup_hypr_gestures.sh) are compiled against
    # one Hyprland's headers; after a Hyprland upgrade they fail to load until
    # rebuilt. Only worth the (slow) rebuild when Hyprland actually changed and
    # there are plugins to rebuild.
    hypr_after="$(pacman -Q hyprland 2>/dev/null)"
    if [[ "${hypr_before}" != "${hypr_after}" ]] && command -v hyprpm &>/dev/null &&
        hyprpm list 2>/dev/null | grep -q 'Plugin'; then
        section "Hyprland changed (${hypr_before#hyprland } -> ${hypr_after#hyprland }) -- rebuilding hyprpm plugins"
        if hyprpm update; then
            if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
                hyprpm reload -n || failed_steps+=("hyprpm reload")
            fi
        else
            failed_steps+=("hyprpm plugin rebuild (hyprpm update)")
        fi
    fi
fi

# --------------------------------------------------- // 5. Configs
if [[ ${SKIP_REPO} -eq 0 && ${repo_usable} -eq 1 ]]; then
    section "Syncing repo configs into ~/.config"
    "${scrDir}/sync_configs.sh" --apply || failed_steps+=("config sync (sync_configs.sh --apply)")

    # --------------------------------------------------- // 6. Theme
    if grep -q '^Configs/configs/theme-switcher/' <<<"${repo_changed_files}"; then
        CURRENT="$HOME/.config/theme-switcher/current-theme.json"
        theme="$(jq -r '.theme // empty' "${CURRENT}" 2>/dev/null)"
        if [[ -n "${theme}" ]]; then
            section "Theme switcher changed -- re-applying '${theme}'"
            THEME_PATH="$HOME/.config/theme-switcher/themes/${theme}"
            theme_args=("${theme}")
            # A dynamic_colors theme called without a wallpaper opens a
            # picker; hand it the one it already has (same lookup order as
            # hypr/restore_theme.sh) so the update stays hands-off.
            if [[ "$(jq -r '.dynamic_colors // false' "${THEME_PATH}/theme.json" 2>/dev/null)" == "true" ]]; then
                wp=""
                [[ -r "${THEME_PATH}/current-wallpaper.txt" ]] && wp="$(cat "${THEME_PATH}/current-wallpaper.txt")"
                [[ -n "${wp}" ]] || wp="$(jq -r '.wallpaper // empty' "${CURRENT}" 2>/dev/null)"
                [[ -n "${wp}" && "${wp}" != /* ]] && wp="${THEME_PATH}/${wp}"
                [[ -n "${wp}" && -f "${wp}" ]] && theme_args+=("${wp}")
            fi
            "$HOME/.config/theme-switcher/apply-theme.sh" "${theme_args[@]}" ||
                failed_steps+=("theme re-apply (apply-theme.sh ${theme})")
        fi
    fi
fi

# --------------------------------------------------- // 7. Report
section "Things to check by hand"
attention=0

# Config files a package update wanted to replace but left alone because
# you'd changed them. pacman never merges these itself.
mapfile -t pacnew < <(find /etc \( -name '*.pacnew' -o -name '*.pacsave' \) 2>/dev/null)
if [[ ${#pacnew[@]} -gt 0 ]]; then
    attention=1
    print_log "${#pacnew[@]} .pacnew/.pacsave file(s) in /etc need merging:"
    printf '  %s\n' "${pacnew[@]}"
    if command -v pacdiff &>/dev/null; then
        print_log "  Review them with: sudo DIFFPROG='nvim -d' pacdiff"
    else
        print_log "  Install pacman-contrib for pacdiff, which walks you through them."
    fi
fi

# Listed, never removed: some "orphans" are things you installed as a
# dependency once and use directly now.
mapfile -t orphans < <(pacman -Qdtq 2>/dev/null)
if [[ ${#orphans[@]} -gt 0 ]]; then
    attention=1
    print_log "${#orphans[@]} orphaned package(s) nothing depends on any more: ${orphans[*]}"
    print_log "  Remove them, if none are things you use, with: sudo pacman -Rns \$(pacman -Qdtq)"
fi

# The running kernel's modules directory disappears when the kernel package
# is upgraded -- new USB devices, filesystems, etc. may fail until a reboot.
if [[ ! -d "/usr/lib/modules/$(uname -r)" ]]; then
    attention=1
    print_log "The kernel was upgraded -- reboot to start using it."
fi

[[ ${attention} -eq 0 ]] && print_log "Nothing."

echo
if [[ ${#failed_steps[@]} -gt 0 ]]; then
    print_log "Update finished with problems in:"
    printf '  - %s\n' "${failed_steps[@]}"
    exit 1
fi
print_log "Update complete."
