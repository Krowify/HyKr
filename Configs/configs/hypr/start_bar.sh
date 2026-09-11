#!/usr/bin/env bash
# Start (or toggle) the bar + notification daemon the ACTIVE theme asks
# for, instead of hardcoding waybar+swaync into hyprland.lua's autostart.
#
# Most themes run the waybar+swaync pair. The Laptop theme replaces both
# with a single Quickshell process (`quickshell -c laptop`) by setting
# "bar": "quickshell-dock" in its theme.json -- apply-theme.sh reads that
# and tears down whichever pair isn't wanted. hyprland.lua's autostart
# didn't know about any of this and ran `waybar` unconditionally, so
# waybar came back on every login (and on every fresh Hyprland start)
# even under the Laptop theme, mapped on top of the Quickshell dock. Same
# for the Super+Ctrl+B "toggle bar" keybind, which only ever toggled
# waybar and so could resurrect it under the Laptop theme too.
#
# Modes:
#   start_bar.sh            start whatever the active theme wants, if not
#                           already running (safe to run more than once)
#   start_bar.sh --toggle   stop it if it's running, start it if it isn't
set -uo pipefail

BASE="$HOME/.config/theme-switcher"
CURRENT="$BASE/current-theme.json"

# Default matches apply-theme.sh's own `.bar // "waybar"` fallback: a
# theme that says nothing about bars, an install that has never applied
# a theme, or a missing jq all mean the classic waybar+swaync pair.
bar_mode="waybar"
if command -v jq >/dev/null 2>&1 && [[ -r "$CURRENT" ]]; then
  theme="$(jq -r '.theme // empty' "$CURRENT" 2>/dev/null || true)"
  theme_json="$BASE/themes/$theme/theme.json"
  if [[ -n "$theme" && -r "$theme_json" ]]; then
    bar_mode="$(jq -r '.bar // "waybar"' "$theme_json" 2>/dev/null || echo waybar)"
  fi
fi

QS_PATTERN='quickshell -c laptop'

running() {
  if [[ "$bar_mode" == "quickshell-dock" ]]; then
    pgrep -f "$QS_PATTERN" >/dev/null 2>&1
  else
    pgrep -x waybar >/dev/null 2>&1
  fi
}

stop_bar() {
  if [[ "$bar_mode" == "quickshell-dock" ]]; then
    pkill -9 -f "$QS_PATTERN" >/dev/null 2>&1 || true
  else
    pkill -x waybar >/dev/null 2>&1 || true
    pkill -x swaync >/dev/null 2>&1 || true
  fi
}

start_bar() {
  if [[ "$bar_mode" == "quickshell-dock" ]]; then
    # Leftovers from another theme: the Quickshell dock carries its own
    # notification daemon, so waybar/swaync still running here would
    # stack a second bar and double every notification.
    pkill -x waybar >/dev/null 2>&1 || true
    pkill -x swaync >/dev/null 2>&1 || true

    if command -v quickshell >/dev/null 2>&1; then
      pgrep -f "$QS_PATTERN" >/dev/null 2>&1 || {
        nohup quickshell -c laptop >/dev/null 2>&1 &
        disown
      }
    else
      echo "start_bar.sh: quickshell not found -- laptop bar/notifications not started" >&2
    fi
  else
    pkill -9 -f "$QS_PATTERN" >/dev/null 2>&1 || true
    pgrep -x waybar >/dev/null 2>&1 || { nohup waybar >/dev/null 2>&1 & disown; }
    pgrep -x swaync >/dev/null 2>&1 || { nohup swaync >/dev/null 2>&1 & disown; }
  fi
}

case "${1:-}" in
  --toggle)
    if running; then stop_bar; else start_bar; fi
    ;;
  *)
    start_bar
    ;;
esac

# Always succeed: hyprland.lua's autostart falls back to a bare
# waybar+swaync on a non-zero exit (see the comment there), and "the bar
# I wanted is already running" is not a failure.
exit 0
