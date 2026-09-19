#!/usr/bin/env bash
# Start (or toggle) the bar + notification daemon the ACTIVE theme asks
# for, instead of hardcoding waybar+swaync into hyprland.lua's autostart.
#
# Most themes run the waybar+swaync pair. The Laptop and Hyperspace themes
# each replace both with a single Quickshell process (`quickshell -c
# laptop` / `-c hyperspace`) by setting "bar": "quickshell-dock" plus
# "quickshell": { "config": ... } in their theme.json -- apply-theme.sh
# reads those and tears down whichever bar isn't wanted. hyprland.lua's autostart
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
# Which `quickshell -c <name>` config the active theme's bar lives in, when
# it has one. Same default as apply-theme.sh's own `.quickshell.config //
# "laptop"`, so the Laptop theme keeps working without naming it and a
# newly added Quickshell theme needs no edit here -- just the two keys in
# its theme.json.
qs_config="laptop"
# Say so when the fallback is taken, rather than defaulting in silence. Every
# way of not resolving the active theme ends at bar_mode=waybar, so on a
# Quickshell theme (Hyperspace, Laptop, Blackturq) a missing or unreadable
# current-theme.json means you log in to waybar instead of your dock, with
# nothing anywhere saying why -- which reads as "my theme switched by itself".
if ! command -v jq >/dev/null 2>&1; then
  echo "start_bar.sh: jq not installed -- cannot read the active theme, defaulting to waybar" >&2
elif [[ ! -r "$CURRENT" ]]; then
  echo "start_bar.sh: ${CURRENT} missing or unreadable -- defaulting to waybar." >&2
  echo "start_bar.sh:   Apply a theme to recreate it: ~/.config/theme-switcher/theme-picker.sh" >&2
else
  theme="$(jq -r '.theme // empty' "$CURRENT" 2>/dev/null || true)"
  theme_json="$BASE/themes/$theme/theme.json"
  if [[ -z "$theme" ]]; then
    echo "start_bar.sh: ${CURRENT} names no theme -- defaulting to waybar" >&2
  elif [[ ! -r "$theme_json" ]]; then
    echo "start_bar.sh: active theme '${theme}' has no readable ${theme_json} -- defaulting to waybar" >&2
  else
    bar_mode="$(jq -r '.bar // "waybar"' "$theme_json" 2>/dev/null || echo waybar)"
    qs_config="$(jq -r '.quickshell.config // "laptop"' "$theme_json" 2>/dev/null || echo laptop)"
  fi
fi

QS_PATTERN="quickshell -c $qs_config"

# Every OTHER theme's Quickshell shell, so starting this one can tear down
# one left running by a theme switch that didn't go through apply-theme.sh
# (or a login where the previous session's shell was still up). Read from
# the themes themselves rather than hardcoded, same as apply-theme.sh does.
stop_other_qs_shells() {
  command -v jq >/dev/null 2>&1 || return 0
  local dir id
  for dir in "$BASE"/themes/*/; do
    [[ -r "$dir/theme.json" ]] || continue
    [[ "$(jq -r '.bar // "waybar"' "$dir/theme.json" 2>/dev/null)" == "quickshell-dock" ]] || continue
    id="$(jq -r '.quickshell.config // "laptop"' "$dir/theme.json" 2>/dev/null)"
    if [[ -n "$id" && "$id" != "null" && "$id" != "$qs_config" ]]; then
      pkill -9 -f "quickshell -c $id" >/dev/null 2>&1 || true
    fi
  done
}

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
    # stack a second bar and double every notification -- and so would
    # another theme's Quickshell shell.
    pkill -x waybar >/dev/null 2>&1 || true
    pkill -x swaync >/dev/null 2>&1 || true
    stop_other_qs_shells

    if command -v quickshell >/dev/null 2>&1; then
      pgrep -f "$QS_PATTERN" >/dev/null 2>&1 || {
        # "$qs_config", never a literal. This line said `-c laptop` while
        # the pgrep above it tested for the ACTIVE theme's config, so under
        # any other Quickshell theme it looked for a shell that wasn't
        # running and then started the Laptop dock instead -- every login,
        # every unlock through lock.sh, every Super+Ctrl+B, each time with a
        # fresh pid. The theme's own bar never started at all.
        nohup quickshell -c "$qs_config" >/dev/null 2>&1 &
        disown
      }
    else
      echo "start_bar.sh: quickshell not found -- $qs_config bar/notifications not started" >&2
    fi
  else
    pkill -9 -f "$QS_PATTERN" >/dev/null 2>&1 || true
    stop_other_qs_shells
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
