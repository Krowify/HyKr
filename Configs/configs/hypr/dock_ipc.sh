#!/usr/bin/env bash
# Call a function on the running Quickshell dock's IpcHandler.
#
#   dock_ipc.sh toggle-notifications
#   dock_ipc.sh toggle-dnd
#   dock_ipc.sh is-dnd        prints true / false
#   dock_ipc.sh count         prints the number of notifications in history
#
# Each theme's Quickshell shell carries its own notification daemon, so the
# Super+N keybind and the control centre's DND tile have to reach the shell.
# They used
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
[[ -z "$action" ]] && { echo "Usage: dock_ipc.sh <toggle-notifications|toggle-dnd|is-dnd|count>" >&2; exit 2; }

case "$action" in
    toggle-notifications) qs_fn="toggleNotifications" ;;
    toggle-dnd)           qs_fn="toggleDnd" ;;
    is-dnd)               qs_fn="isDnd" ;;
    count)                qs_fn="count" ;;
    *) echo "dock_ipc.sh: unknown action '$action'" >&2; exit 2 ;;
esac

# Same default as apply-theme.sh's own `.quickshell.config // "laptop"`.
qs_config="laptop"
if command -v jq >/dev/null 2>&1 && [[ -r "$CURRENT" ]]; then
    theme="$(jq -r '.theme // empty' "$CURRENT" 2>/dev/null || true)"
    # Renamed themes (see apply-theme.sh): an install whose current-theme.json
    # predates the rename still names the old id until the next apply.
    case "$theme" in blackturq) theme=default ;; catppuccin) theme=arch ;; laptop) theme=sakura ;; esac
    theme_json="$BASE/themes/$theme/theme.json"
    if [[ -n "$theme" && -r "$theme_json" ]]; then
        qs_config="$(jq -r '.quickshell.config // "laptop"' "$theme_json" 2>/dev/null || echo laptop)"
    fi
fi

# Nothing to fall back to: with no shell running there is no notification
# center to toggle, so a failed call is simply a no-op. The two queries
# print the bar's answer (the control centre reads it); everything else is
# silent.
command -v quickshell >/dev/null 2>&1 || exit 0
case "$action" in
    is-dnd|count) quickshell -c "$qs_config" ipc call dock "$qs_fn" 2>/dev/null ;;
    *)            quickshell -c "$qs_config" ipc call dock "$qs_fn" >/dev/null 2>&1 || true ;;
esac
