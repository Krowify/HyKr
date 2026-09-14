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
        # Under a Quickshell theme (Laptop, Hyperspace) that shell owns
        # notifications and swaync isn't running, so this entry did nothing
        # there. dock_ipc.sh asks whichever dock the active theme runs -- it
        # flips the same doNotDisturb the notification center's own switch
        # does -- and falls back to swaync-client under the waybar themes.
        ~/.config/hypr/dock_ipc.sh toggle-dnd
        ;;
    *"Night Light"*)
        # -t 5000 to match the Super+Shift+N bind in hyprland.lua -- without it
        # this menu entry started hyprsunset at its default temperature, so the
        # key and the menu produced visibly different results for the same
        # nominal action.
        pkill hyprsunset || hyprsunset -t 5000
        ;;
    *"Caffeine"*)
        pkill hypridle || hypridle
        ;;
    *"Wallpaper"*)
        pkill -9 -x -f 'quickshell -c wallpaper-picker'; ~/.config/quickshell/wallpaper-picker/launch.sh
        ;;
    *"Lock Screen"*)
        # lock.sh, not hyprlock directly -- see hypr/lock.sh: it restores the
        # active theme's bar once you unlock.
        ~/.config/hypr/lock.sh
        ;;
    *"Logout"*)
        wlogout
        ;;
esac
