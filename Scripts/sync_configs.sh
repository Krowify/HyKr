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

set -e

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    exit 1
}

APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

drift_found=0

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

    if [[ -d "$src" ]]; then
        while IFS= read -r -d '' f; do
            rel="${f#"$src"/}"
            check_file "$f" "${dst}/${rel}"
        done < <(find "$src" -type f -print0)
    else
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
