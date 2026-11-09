#!/usr/bin/env bash
# Start (or toggle) the ACTIVE theme's bar: one Quickshell process that is
# also the notification daemon (`quickshell -c laptop` for Sakura/Default,
# `-c bar` for the rest), named by "quickshell": { "config": ... } in the
# theme's theme.json. Used by hyprland.lua's autostart, lock.sh (after an
# unlock) and the Super+Ctrl+B "toggle bar" keybind.
#
# Modes:
#   start_bar.sh            start the active theme's bar, if not already
#                           running (safe to run more than once)
#   start_bar.sh --toggle   stop it if it's running, start it if it isn't
set -uo pipefail

BASE="$HOME/.config/theme-switcher"
CURRENT="$BASE/current-theme.json"

# Which `quickshell -c <name>` config the active theme's bar lives in. Same
# default as apply-theme.sh's own `.quickshell.config // "laptop"`, so a
# newly added theme needs no edit here -- just the key in its theme.json.
qs_config="laptop"
# Say so when the default is taken, rather than defaulting in silence: a
# missing or unreadable current-theme.json means you log in to the Laptop
# dock instead of your theme's bar, which otherwise reads as "my theme
# switched by itself".
if ! command -v jq >/dev/null 2>&1; then
  echo "start_bar.sh: jq not installed -- cannot read the active theme, defaulting to '$qs_config'" >&2
elif [[ ! -r "$CURRENT" ]]; then
  echo "start_bar.sh: ${CURRENT} missing or unreadable -- defaulting to '$qs_config'." >&2
  echo "start_bar.sh:   Apply a theme to recreate it: ~/.config/theme-switcher/theme-picker.sh" >&2
else
  theme="$(jq -r '.theme // empty' "$CURRENT" 2>/dev/null || true)"
  # Renamed themes (see apply-theme.sh): an install whose current-theme.json
  # predates the rename still names the old id until the next apply.
  case "$theme" in blackturq) theme=default ;; catppuccin) theme=arch ;; laptop) theme=sakura ;; esac
  theme_json="$BASE/themes/$theme/theme.json"
  if [[ -z "$theme" ]]; then
    echo "start_bar.sh: ${CURRENT} names no theme -- defaulting to '$qs_config'" >&2
  elif [[ ! -r "$theme_json" ]]; then
    echo "start_bar.sh: active theme '${theme}' has no readable ${theme_json} -- defaulting to '$qs_config'" >&2
  else
    qs_config="$(jq -r '.quickshell.config // "laptop"' "$theme_json" 2>/dev/null || echo laptop)"
  fi
fi

# Finding and stopping Quickshell bars goes through theme-switcher's
# qs-stop.sh, shared with apply-theme.sh. It reads each `quickshell`/`qs`
# process's real argv instead of `pgrep -f "quickshell -c <name>"`, which
# both missed a shell launched as `qs -c laptop` / `--config` / `-p` / with a
# flag in between -- so it was never stopped on a theme switch -- AND reported
# such a shell as not running, so this script launched a second copy of it.
# Either way: two bars stacked at the top of the screen.
#
# The pkill fallbacks only matter on an install whose theme-switcher hasn't
# been synced since qs-stop.sh was added.
QS_STOP="$BASE/qs-stop.sh"
QS_PATTERN="quickshell -c $qs_config"

# Every OTHER bar shell: one left running by a theme switch that didn't go
# through apply-theme.sh, a login where the previous session's shell was
# still up, or a config no theme names any more (`-c hyperspace`, from
# before quickshell/hyperspace/ became quickshell/bar/).
stop_other_qs_shells() {
  if [[ -r "$QS_STOP" ]]; then
    bash "$QS_STOP" --keep "$qs_config" || true
  fi
}

running() {
  if [[ -r "$QS_STOP" ]]; then
    bash "$QS_STOP" --running "$qs_config"
  else
    pgrep -f "$QS_PATTERN" >/dev/null 2>&1
  fi
}

stop_bar() {
  if [[ -r "$QS_STOP" ]]; then
    bash "$QS_STOP" --only "$qs_config" || true
  else
    pkill -9 -f "$QS_PATTERN" >/dev/null 2>&1 || true
  fi
}

start_bar() {
  # waybar and swaync are no longer part of HyKr, but an install upgraded
  # from an older version may still have them: a leftover waybar stacks a
  # second bar, and swaync fights the shell for the notification name.
  pkill -x waybar >/dev/null 2>&1 || true
  pkill -x swaync >/dev/null 2>&1 || true
  stop_other_qs_shells

  if command -v quickshell >/dev/null 2>&1; then
    running || {
      nohup quickshell -c "$qs_config" >/dev/null 2>&1 &
      disown
    }
  else
    echo "start_bar.sh: quickshell not found -- $qs_config bar/notifications not started" >&2
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

# "The bar I wanted is already running" is not a failure.
exit 0
