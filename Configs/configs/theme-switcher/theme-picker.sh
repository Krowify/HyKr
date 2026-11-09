#!/usr/bin/env bash
# Theme picker. This used to be a rofi/wofi menu; the picker is now the HyKr
# desktop shell's (quickshell/hykr/ThemePicker.qml, Super+Shift+T). Kept as a
# wrapper so anything still calling this path -- a keybind of your own, a
# script, start_bar.sh's "apply a theme" hint -- opens the same picker.
#
# To apply a theme without any picker: ~/.config/theme-switcher/apply-theme.sh <theme>
exec "$HOME/.config/hypr/hykr.sh" themes open
