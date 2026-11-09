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
    command -v brightnessctl >/dev/null 2>&1 || { echo "fn_keys.sh: brightnessctl not installed" >&2; return 0; }
    # Not `dev="$(kbd_device)" || ...`: that takes kbd_device's exit status,
    # which is grep's -- so "brightnessctl is installed but this machine
    # exposes no kbd_backlight device" reported the wrong cause and the
    # specific message below was unreachable. Check the two separately.
    dev="$(kbd_device || true)"
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

# Set one input device's enabled state at runtime. Prints nothing; returns
# 0 only if Hyprland replied "ok".
#
# Lua config first: `hyprctl eval` running hl.device(), the Lua config's
# per-device block. Hyprland's Lua IPC has no `keyword` request at all, so
# the keyword forms below only ever got "unknown request" back there and
# the touchpad never toggled. hl.device() merges the one key into any
# existing per-device settings rather than replacing them, and schedules an
# input-device refresh, so it takes effect immediately.
#
# Then hyprlang: `keyword`, whose path changed shape across versions
# (device:<name>:enabled became device[<name>]:enabled), so try the bracket
# form first and fall back to the colon form rather than pinning one.
#
# Every step checks the reply text, not hyprctl's exit status: hyprctl can
# exit 0 on "unknown request" or an "error: ..." reply, which made the old
# `||` chain stop at the first call even when nothing had changed.
set_device_enabled() {
    local name="$1" want="$2" lua_name reply
    # Escape for a Lua double-quoted string. `hyprctl devices` names are
    # already sanitised (lowercase, dashes), so this is belt and braces.
    lua_name="${name//\\/\\\\}"
    lua_name="${lua_name//\"/\\\"}"

    reply="$(hyprctl eval "hl.device({ name = \"$lua_name\", enabled = $want })" 2>/dev/null)" || reply=""
    [[ "$reply" == ok* ]] && return 0

    reply="$(hyprctl keyword "device[$name]:enabled" "$want" 2>/dev/null)" || reply=""
    [[ "$reply" == ok* ]] && return 0

    reply="$(hyprctl keyword "device:$name:enabled" "$want" 2>/dev/null)" || reply=""
    [[ "$reply" == ok* ]] && return 0

    return 1
}

# Hyprland disables a pointer by device name, which has to come from
# `hyprctl devices` -- it differs per machine.
touchpad_toggle() {
    command -v hyprctl >/dev/null 2>&1 || return 0
    command -v jq >/dev/null 2>&1 || { echo "fn_keys.sh: jq not installed" >&2; return 0; }

    local name
    name="$(hyprctl devices -j 2>/dev/null \
        | jq -r '.mice[]?.name | select(test("touch *pad"; "i"))' \
        | head -n1)"
    [[ -n "$name" ]] || { echo "fn_keys.sh: no touchpad in 'hyprctl devices'" >&2; return 0; }

    # No query for a device's current enabled state, so track it ourselves.
    # Only flip the marker once Hyprland has accepted the change: flipping it
    # first meant a rejected call left the marker saying "disabled" while the
    # touchpad was still on, so the next press "enabled" it -- a no-op.
    local state_file="${XDG_RUNTIME_DIR:-/tmp}/hykr-touchpad-disabled"
    local want=false
    [[ -f "$state_file" ]] && want=true

    if set_device_enabled "$name" "$want"; then
        if [[ "$want" == true ]]; then rm -f "$state_file"; else touch "$state_file"; fi
    else
        echo "fn_keys.sh: hyprctl rejected hl.device() and both device keyword forms for '$name'" >&2
    fi
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

    # `nmcli radio all` prints four fields -- WIFI-HW WIFI WWAN-HW WWAN -- and
    # WIFI-HW is the *hardware* rfkill state, which stays "enabled" after
    # `nmcli radio all off`. Grepping the whole table therefore always matched,
    # so every press took the "turn off" branch and airplane mode could never
    # be turned back off. Ask for the one field that tracks the software
    # state, terse so there's no header row to match either.
    if [[ "$(nmcli -t -f WIFI radio all 2>/dev/null)" == "enabled" ]]; then
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
