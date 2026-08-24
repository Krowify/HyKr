#!/usr/bin/env bash
# Runs on selection in shell.qml. Delegates to HyKr's shared wallpaper
# pipeline (awww + pywal + kitty/starship/swaync/pywalfox) instead of
# upstream hyprquickpaper's bare `awww img "$1"`.
~/.config/hypr/apply_wallpaper.sh "$1"
