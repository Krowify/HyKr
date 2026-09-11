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
        # Under the Laptop theme the Quickshell dock owns notifications and
        # swaync isn't running, so this entry did nothing there. Ask the dock
        # first -- it flips the same doNotDisturb the notification center's own
        # switch does -- and fall back to swaync-client for the waybar themes,
        # where the ipc call finds no laptop shell and fails.
        quickshell -c laptop ipc call dock toggleDnd >/dev/null 2>&1 || swaync-client --toggle-dnd
        ;;
    *"Night Light"*)
        pkill hyprsunset || hyprsunset
        ;;
    *"Caffeine"*)
        pkill hypridle || hypridle
        ;;
    *"Wallpaper"*)
        pkill -9 -x -f 'quickshell -c wallpaper-picker'; ~/.config/quickshell/wallpaper-picker/launch.sh
        ;;
    *"Lock Screen"*)
        hyprlock
        ;;
    *"Logout"*)
        wlogout
        ;;
esac
