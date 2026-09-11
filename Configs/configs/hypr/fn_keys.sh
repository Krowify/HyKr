#!/usr/bin/env bash
# The two function-row actions that can't be a one-line exec_cmd in
# hyprland.lua, because both have to discover a device name first.
#
#   fn_keys.sh kbd-light up|down|toggle   laptop keyboard backlight (F8)
#   fn_keys.sh touchpad                   enable/disable touchpad (F4)
#   fn_keys.sh airplane                   all radios off/on (F12)
#
# Everything else on the row (brightness, mic mute, bluetooth) is a plain
# command and is bound directly in hyprland.lua.
#
# Always exits 0. These are bound to hardware keys that may not even emit
# a keycode on a given machine, and a key that quietly does nothing beats
# one that pops an error every press.
set -uo pipefail

# brightnessctl exposes the keyboard backlight as a separate device, named
# differently per vendor (dell::kbd_backlight, platform::kbd_backlight,
# asus::kbd_backlight, ...). Pick the first whose name ends in
# kbd_backlight rather than hardcoding one vendor's.
kbd_device() {
    command -v brightnessctl >/dev/null 2>&1 || return 1
    brightnessctl -l -m 2>/dev/null | cut -d, -f1 | grep -m1 'kbd_backlight$'
}

kbd_light() {
    local dev step="${2:-10}"
    dev="$(kbd_device)" || { echo "fn_keys.sh: brightnessctl not installed" >&2; return 0; }
    [[ -n "$dev" ]] || { echo "fn_keys.sh: no kbd_backlight device -- this laptop likely drives its keyboard light in firmware, not via sysfs" >&2; return 0; }

    case "${1:-}" in
        up)   brightnessctl -q -d "$dev" set "${step}%+" ;;
        down) brightnessctl -q -d "$dev" set "${step}%-" ;;
        # MSI's key is a single cycling key, not a pair: step through
        # off -> mid -> max -> off rather than ramping in one direction.
        toggle)
            local cur max
            cur="$(brightnessctl -d "$dev" get 2>/dev/null || echo 0)"
            max="$(brightnessctl -d "$dev" max 2>/dev/null || echo 0)"
            [[ "$max" -gt 0 ]] || return 0
            if   [[ "$cur" -eq 0 ]];        then brightnessctl -q -d "$dev" set "$(( max / 2 ))"
            elif [[ "$cur" -lt "$max" ]];   then brightnessctl -q -d "$dev" set "$max"
            else                                 brightnessctl -q -d "$dev" set 0
            fi
            ;;
        *) echo "usage: fn_keys.sh kbd-light up|down|toggle" >&2 ;;
    esac
    return 0
}

# Hyprland disables a pointer by device name, which has to come from
# `hyprctl devices` -- it differs per machine. The keyword path changed
# shape across Hyprland versions (device:<name>:enabled became
# device[<name>]:enabled), so try the bracket form first and fall back to
# the colon form rather than pinning one and breaking on an upgrade.
touchpad_toggle() {
    command -v hyprctl >/dev/null 2>&1 || return 0
    command -v jq >/dev/null 2>&1 || { echo "fn_keys.sh: jq not installed" >&2; return 0; }

    local name
    name="$(hyprctl devices -j 2>/dev/null \
        | jq -r '.mice[]?.name | select(test("touch *pad"; "i"))' \
        | head -n1)"
    [[ -n "$name" ]] || { echo "fn_keys.sh: no touchpad in 'hyprctl devices'" >&2; return 0; }

    # No query for a device's current enabled state, so track it ourselves.
    local state_file="${XDG_RUNTIME_DIR:-/tmp}/hykr-touchpad-disabled"
    local want
    if [[ -f "$state_file" ]]; then want=true; rm -f "$state_file"; else want=false; touch "$state_file"; fi

    hyprctl keyword "device[$name]:enabled" "$want" >/dev/null 2>&1 \
        || hyprctl keyword "device:$name:enabled" "$want" >/dev/null 2>&1 \
        || echo "fn_keys.sh: hyprctl rejected both device keyword forms" >&2
    return 0
}

# Deliberately NOT `rfkill block all`: /dev/rfkill is root-only on a stock
# Arch install, so an rfkill toggle bound to a bare keypress just fails
# silently. nmcli goes through NetworkManager's polkit rules and works as
# the logged-in user, and bluetoothctl likewise -- together they cover what
# the key's aeroplane icon implies. NetworkManager and bluez-utils are both
# in pkg_core.lst.
airplane_toggle() {
    command -v nmcli >/dev/null 2>&1 || { echo "fn_keys.sh: nmcli not installed" >&2; return 0; }

    if nmcli radio all 2>/dev/null | grep -q enabled; then
        nmcli radio all off >/dev/null 2>&1
        command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl power off >/dev/null 2>&1
        echo "airplane mode: on" >&2
    else
        nmcli radio all on >/dev/null 2>&1
        command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl power on >/dev/null 2>&1
        echo "airplane mode: off" >&2
    fi
    return 0
}

case "${1:-}" in
    kbd-light) shift; kbd_light "$@" ;;
    touchpad)  touchpad_toggle ;;
    airplane)  airplane_toggle ;;
    *) echo "usage: fn_keys.sh {kbd-light up|down|toggle | touchpad | airplane}" >&2 ;;
esac
exit 0
