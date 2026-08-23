#!/usr/bin/env bash
# Symlinks every app manifest in Scripts/dots/*.toml from Configs/ into $HOME.

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

for manifest in "${dotsDir}"/*.toml; do
    source_rel="$(grep '^source' "$manifest" | cut -d'"' -f2)"
    target_rel="$(grep '^target' "$manifest" | cut -d'"' -f2)"

    src="${repoDir}/${source_rel}"
    dst="${target_rel/#\~/$HOME}"

    link_dot "$src" "$dst"
done

# ~/.config/hypr/wallpaper.sh (super+shift+W) picks from ~/wallpapers, which
# nothing else populates -- link it to the repo's bundled wallpaper set.
link_dot "${repoDir}/Source/wallpapers" "$HOME/wallpapers"

# hyprland.conf sources ~/.cache/wal/colors-hyprland — seed it so a fresh
# install doesn't hand Hyprland a config that fails to parse.
if [ ! -f "$HOME/.cache/wal/colors-hyprland" ]; then
    if command -v wal >/dev/null 2>&1; then
        print_log "No pywal theme yet — generating one from the default wallpaper"
        wal -i "${repoDir}/Source/wallpapers/pywallpaper.jpg" -n --cols16
    else
        print_log "python-pywal not installed yet — install it, then run: wal -i <wallpaper> -n"
    fi
fi
