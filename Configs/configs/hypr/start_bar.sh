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
#   start_bar.sh --desktop  only make sure the desktop shell (quickshell/hykr)
#                           is running
#
# A bar that dies during startup (a QML error in its config) is reported on
# stderr and on screen via `hyprctl notify`, and makes this exit 1; the
# shell's output is kept in $XDG_RUNTIME_DIR/hykr-bar.log.
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

# The bar's own output, rewritten on every start. $XDG_RUNTIME_DIR, not
# /tmp: it is per-user and 0700, so no other local user can pre-create
# this path. (Quickshell also keeps its own log; the path is in the first
# lines of this file.)
BAR_LOG="${XDG_RUNTIME_DIR:-$HOME/.cache}/hykr-bar.log"

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

# Start `quickshell -c <config>` with its output in <log>, and watch it
# briefly. The output goes to a file, not /dev/null: a config that fails to
# load (a QML error) makes quickshell exit within a second, and with its
# output discarded that looked exactly like a successful start -- no bar, and
# nothing anywhere saying why. A shell still alive at the end of the window
# has loaded its config.
launch_watched() {
  local config="$1" log="$2" what="$3"
  nohup quickshell -c "$config" >"$log" 2>&1 &
  local pid=$!
  disown

  local _
  for _ in {1..12}; do
    sleep 0.25
    kill -0 "$pid" 2>/dev/null || {
      echo "start_bar.sh: 'quickshell -c $config' exited during startup. Its output:" >&2
      tail -n 15 "$log" | sed 's/^/  /' >&2
      report_failure "$what failed to start -- see $log"
      return 1
    }
  done
}

start_bar() {
  # waybar and swaync are no longer part of HyKr, but an install upgraded
  # from an older version may still have them: a leftover waybar stacks a
  # second bar, and swaync fights the shell for the notification name.
  pkill -x waybar >/dev/null 2>&1 || true
  pkill -x swaync >/dev/null 2>&1 || true
  stop_other_qs_shells

  if ! command -v quickshell >/dev/null 2>&1; then
    report_failure "quickshell is not installed -- the $qs_config bar was not started"
    return
  fi
  running && return

  launch_watched "$qs_config" "$BAR_LOG" "the $qs_config bar"
}

# The desktop shell (quickshell/hykr: launcher, clipboard, pickers, control
# centre) runs alongside whichever bar the theme uses, in a process of its
# own, so a QML error in one can't take the other down. Started here so that
# every path that brings the bar up -- login, unlock, theme apply -- also
# brings it up. Never stopped by --toggle: Super+Ctrl+B hides the bar, not
# the launcher.
DESKTOP_LOG="${XDG_RUNTIME_DIR:-$HOME/.cache}/hykr-desktop.log"
ensure_desktop_shell() {
  command -v quickshell >/dev/null 2>&1 || return 0
  [[ -r "$HOME/.config/quickshell/hykr/shell.qml" ]] || return 0
  if [[ -r "$QS_STOP" ]]; then
    bash "$QS_STOP" --running hykr && return 0
  else
    pgrep -f "quickshell -c hykr" >/dev/null 2>&1 && return 0
  fi
  launch_watched hykr "$DESKTOP_LOG" "the HyKr desktop shell (launcher, clipboard)"
}

# Say so on screen as well as on stderr: at login (hyprland.lua's autostart)
# and after an unlock (lock.sh) there is no terminal to read. notify-send is
# no use here -- the bar IS the notification daemon, so it is exactly what is
# missing -- but `hyprctl notify` is drawn by Hyprland itself.
failed=0
report_failure() {
  failed=1
  echo "start_bar.sh: $1" >&2
  if command -v hyprctl >/dev/null 2>&1 &&
     [[ -n "${WAYLAND_DISPLAY:-}" || -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    timeout 3 hyprctl notify 3 15000 "rgb(ff5555)" "HyKr: $1" >/dev/null 2>&1 || true
  fi
}

case "${1:-}" in
  --toggle)
    if running; then stop_bar; else start_bar; fi
    ;;
  --desktop)
    ensure_desktop_shell
    ;;
  *)
    start_bar
    ensure_desktop_shell
    ;;
esac

# Non-zero only when a shell was supposed to start and didn't (apply-theme.sh
# reports it). "The bar I wanted is already running" is not a failure.
exit "$failed"
