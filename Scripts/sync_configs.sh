#!/usr/bin/env bash
# Reports (and, with --apply, fixes) drift between the repo and live
# configs on THIS machine.
#
# link_dots.sh symlinks each Scripts/dots/*.toml target to its repo
# source, but apply-theme.sh's de_symlink() permanently converts a
# handful of those (hypr, wofi, kitty, waybar, swaync, wlogout,
# fastfetch, starship.toml, gtk-4.0) into independent real copies the
# first time a theme is applied -- on purpose, so a theme switch never
# silently edits tracked repo files. From that point on, a plain
# `git pull` stops reaching those targets entirely: this bit us hard
# across a whole session of "why doesn't this Hyprland fix show up"
# debugging, chasing symptoms that were really just "the live file
# never got the commit."
#
# This script never deletes or overwrites anything you added locally
# (generated theme output, hyprmod's own files, etc.) -- it only ever
# copies a repo-tracked file over its live counterpart, and only for
# files that actually differ or are missing live.
#
# One class of file is tracked in the repo AND rewritten at runtime, so it
# needs an explicit exemption to keep that promise true: see SKIP_PATTERNS.

set -e

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    exit 1
}

APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

drift_found=0

# Tracked files that are legitimately rewritten on this machine at runtime by
# apply-theme.sh / apply_wallpaper.sh. The repo copy of each is only a seed --
# the truth on a live install is whatever the last theme apply or wallpaper
# pick generated. Reporting them as "drift" is noise, and copying the repo's
# version over them with --apply throws away your actual theming, which is
# exactly what the header above promises not to do.
#
# Entries are "<manifest>:<path within it>" because the same filename means
# different things per app: waybar/config and wlogout/layout are generated,
# but wofi/config is a hand-written file that SHOULD be synced. A bare
# filename pattern could not tell those apart.
#
# Only applies to a file that already exists locally -- a missing one is still
# seeded from the repo, so a fresh install gets its defaults.
SKIP_PATTERNS=(
    'fastfetch:config.jsonc'
    'gtk-4.0:gtk.css'
    'hypr:hyprlock.conf'
    'kitty:current-theme.conf'
    'quickshell:laptop/colors.json'
    'quickshell:wallpaper-picker/config.json'
    'spicetify:color.ini'
    'starship:starship.toml'
    'swaync:config.json'
    'swaync:style.css'
    'theme-switcher:themes/*/colors.json'
    'waybar:config'
    'waybar:style.css'
    'wlogout:layout'
    'wlogout:style.css'
    'wofi:style.css'
)

should_skip() {
    local rel="$1" pattern
    for pattern in "${SKIP_PATTERNS[@]}"; do
        # shellcheck disable=SC2053 -- glob match is the point
        [[ "$rel" == $pattern ]] && return 0
    done
    return 1
}

# One tracked file vs its live counterpart.
check_file() {
    local src="$1" dst="$2"

    if [[ ! -e "$dst" ]]; then
        echo "  [missing]  $dst"
        drift_found=1
        if [[ $APPLY -eq 1 ]]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            echo "             -> copied"
        fi
        return
    fi

    if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
        echo "  [differs]  $dst"
        drift_found=1
        if [[ $APPLY -eq 1 ]]; then
            cp "$src" "$dst"
            echo "             -> copied"
        fi
    fi
}

for manifest in "${dotsDir}"/*.toml; do
    source_rel="$(grep '^source' "$manifest" | cut -d'"' -f2)"
    target_rel="$(grep '^target' "$manifest" | cut -d'"' -f2)"
    [[ -z "$source_rel" || -z "$target_rel" ]] && continue

    src="${repoDir}/${source_rel}"
    dst="${target_rel/#\~/$HOME}"

    [[ -e "$dst" ]] || continue

    if [[ -L "$dst" ]]; then
        continue # still symlinked into the repo -- git pull already reaches it
    fi

    print_log "Detached: ${dst} (was a symlink to ${src}, now a real copy)"

    app="$(basename "$manifest" .toml)"

    if [[ -d "$src" ]]; then
        while IFS= read -r -d '' f; do
            rel="${f#"$src"/}"
            # Skip a generated file only when one already exists locally. If
            # it is missing entirely it still needs seeding from the repo's
            # committed default -- skipping unconditionally meant a newly
            # added generated file (quickshell/laptop/colors.json) never
            # landed on an existing install at all, and the app reading it
            # silently fell back to its built-in default forever.
            if [[ -e "${dst}/${rel}" ]] && should_skip "${app}:${rel}"; then
                continue
            fi
            check_file "$f" "${dst}/${rel}"
        done < <(find "$src" -type f -print0)
    else
        # Single-file manifest (starship.toml, .zshrc): the skip check has to
        # happen here too, or a wholly generated file like starship.toml is
        # clobbered on every --apply.
        if [[ -e "$dst" ]] && should_skip "${app}:$(basename "$src")"; then
            continue
        fi
        check_file "$src" "$dst"
    fi
done

echo
if [[ $drift_found -eq 0 ]]; then
    print_log "No drift found -- every detached config matches the repo."
elif [[ $APPLY -eq 1 ]]; then
    print_log "Drift copied over. Re-run without --apply any time to re-check."
else
    print_log "Drift found (listed above). Re-run with --apply to copy the repo versions over."
fi
