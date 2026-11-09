#!/bin/bash
# Wallpaper picker. This used to be a rofi/wofi menu; the picker is now the
# HyKr desktop shell's (quickshell/hykr/WallpaperPicker.qml, Super+Shift+W),
# which runs apply_wallpaper.sh (awww + the pywal colour pipeline) on the
# wallpaper you pick, exactly as this script did. Kept as a wrapper so
# anything still calling this path opens the same picker.
#
# To set a wallpaper without any picker: ~/.config/hypr/apply_wallpaper.sh <image>
exec "$HOME/.config/hypr/hykr.sh" wallpaper open
