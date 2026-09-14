#!/usr/bin/env bash
# Call a function on the running Quickshell dock's IpcHandler, falling back
# to swaync-client when the active theme has no such dock.
#
#   dock_ipc.sh toggle-notifications
#   dock_ipc.sh toggle-dnd
#
# The Quickshell themes (Laptop, Hyperspace) replace swaync entirely -- each
# shell carries its own notification daemon -- so the Super+N keybind and
# quick_settings.sh's DND entry have to reach the shell instead. They used
# to do that by shelling out to a hardcoded `quickshell -c laptop ipc call
# dock ...`, which silently did nothing under any OTHER Quickshell theme.
# This resolves the config name from the active theme (theme.json's
# .quickshell.config) the same way apply-theme.sh and start_bar.sh do, so
# adding a Quickshell theme needs no edit at either call site.
#
# Both shells name their handler "dock" and expose the same function names,
# which is what lets this stay one script rather than one per theme.
set -uo pipefail

BASE="$HOME/.config/theme-switcher"
CURRENT="$BASE/current-theme.json"

action="${1:-}"
[[ -z "$action" ]] && { echo "Usage: dock_ipc.sh <toggle-notifications|toggle-dnd>" >&2; exit 2; }

case "$action" in
    toggle-notifications) qs_fn="toggleNotifications"; fallback=(swaync-client -t -sw) ;;
    toggle-dnd)           qs_fn="toggleDnd";           fallback=(swaync-client --toggle-dnd) ;;
    *) echo "dock_ipc.sh: unknown action '$action'" >&2; exit 2 ;;
esac

# Same default as apply-theme.sh's own `.quickshell.config // "laptop"`.
qs_config="laptop"
if command -v jq >/dev/null 2>&1 && [[ -r "$CURRENT" ]]; then
    theme="$(jq -r '.theme // empty' "$CURRENT" 2>/dev/null || true)"
    theme_json="$BASE/themes/$theme/theme.json"
    if [[ -n "$theme" && -r "$theme_json" ]]; then
        qs_config="$(jq -r '.quickshell.config // "laptop"' "$theme_json" 2>/dev/null || echo laptop)"
    fi
fi

# The ipc call is the test: under a waybar theme no such shell is running,
# so it fails and the swaync path runs unchanged -- exactly the behaviour
# the hardcoded version had, just no longer tied to one config name.
if command -v quickshell >/dev/null 2>&1 &&
   quickshell -c "$qs_config" ipc call dock "$qs_fn" >/dev/null 2>&1; then
    exit 0
fi

command -v "${fallback[0]}" >/dev/null 2>&1 || exit 0
"${fallback[@]}" >/dev/null 2>&1 || true
