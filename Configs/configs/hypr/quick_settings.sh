#!/bin/bash
# Lightweight quick-settings menu via wofi, wrapping existing keybind
# actions (hyprsunset/hypridle toggles, the quickshell wallpaper picker,
# hyprlock, wlogout) plus Wi-Fi/Bluetooth/DND toggles that don't have a
# dedicated keybind.

options="󰖩  Toggle Wi-Fi
󰂯  Toggle Bluetooth
󰂛  Toggle DND
󰛨  Toggle Night Light
󰤄  Toggle Caffeine (idle inhibit)
󰸉  Change Wallpaper
󰌾  Lock Screen
⏻  Logout Menu"

chosen=$(echo "$options" | wofi --dmenu --prompt "Quick Settings:" -n)

case "$chosen" in
    *"Wi-Fi"*)
        nmcli radio wifi "$(nmcli radio wifi | grep -q enabled && echo off || echo on)"
        ;;
    *"Bluetooth"*)
        bluetoothctl power "$(bluetoothctl show | grep -q 'Powered: yes' && echo off || echo on)"
        ;;
    *"DND"*)
        swaync-client --toggle-dnd
        ;;
    *"Night Light"*)
        pkill hyprsunset || hyprsunset
        ;;
    *"Caffeine"*)
        pkill hypridle || hypridle
        ;;
    *"Wallpaper"*)
        pkill -9 -f 'quickshell -c wallpaper-picker'; ~/.config/quickshell/wallpaper-picker/launch.sh
        ;;
    *"Lock Screen"*)
        hyprlock
        ;;
    *"Logout"*)
        wlogout
        ;;
esac
