#!/bin/bash
# config.json can't have $HOME baked in at commit time -- every user's
# home dir differs, and QML's file:// URIs don't expand ~ or $HOME -- so
# this rewrites it with the real path on every launch (idempotent, cheap)
# and then starts the picker.
set -e

DIR="$(dirname "$(realpath "$0")")"

# ~/.config/quickshell is normally symlinked straight into the repo
# (Scripts/dots/quickshell.toml); if it's still a symlink (fresh install,
# nothing has de-symlinked it yet), rewriting config.json in place would
# edit the tracked repo file. De-symlink to a real, independent copy
# first -- same pattern apply-theme.sh's de_symlink() uses for hypr,
# waybar, gtk-4.0, etc.
if [ -L "$HOME/.config/quickshell" ]; then
    real="$(readlink -f "$HOME/.config/quickshell")"
    rm -f "$HOME/.config/quickshell"
    cp -r "$real" "$HOME/.config/quickshell"
    DIR="$HOME/.config/quickshell/wallpaper-picker"
fi

CONFIG="$DIR/config.json"

sed -i \
    -e "s#\"wallpaper_path\": \".*\"#\"wallpaper_path\": \"$HOME/wallpapers/\"#" \
    -e "s#\"cache_path\": \".*\"#\"cache_path\": \"$HOME/.cache/quickshell/wallpaper-picker-thumbs/\"#" \
    "$CONFIG"

exec quickshell -c wallpaper-picker
