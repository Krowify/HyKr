#!/usr/bin/env bash
# Volume / mic / brightness keys: make the change, then show the new level in
# the desktop shell's on-screen display (quickshell/hykr/Osd.qml).
#
#   osd.sh volume up|down|mute
#   osd.sh mic mute
#   osd.sh brightness up|down
#
# The commands are the ones these keys always ran (pamixer, 5% steps;
# brightnessctl, 5% steps). The OSD call runs in the background and its
# failure is ignored: with the desktop shell down, the key still works, it
# just shows nothing. That is also why this doesn't go through hykr.sh --
# starting the shell from a key that may be auto-repeating would only slow
# the key down.
set -uo pipefail

kind="${1:-}"
action="${2:-}"

case "$kind $action" in
  "volume up")       pamixer -i 5 ;;
  "volume down")     pamixer -d 5 ;;
  "volume mute")     pamixer -t ;;
  "mic mute")        pamixer --default-source -t ;;
  "brightness up")   brightnessctl -q set +5% ;;
  "brightness down") brightnessctl -q set 5%- ;;
  *) echo "usage: osd.sh volume up|down|mute | mic mute | brightness up|down" >&2; exit 2 ;;
esac

value=0
muted=false
case "$kind" in
  volume)
    value="$(pamixer --get-volume 2>/dev/null || echo 0)"
    muted="$(pamixer --get-mute 2>/dev/null || echo false)"
    ;;
  mic)
    value="$(pamixer --default-source --get-volume 2>/dev/null || echo 0)"
    muted="$(pamixer --default-source --get-mute 2>/dev/null || echo false)"
    ;;
  brightness)
    value="$(brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { sub("%", "", $4); print $4 }')"
    ;;
esac
[[ "$value" =~ ^[0-9]+$ ]] || value=0
[[ "$muted" == "true" ]] || muted=false

command -v quickshell >/dev/null 2>&1 &&
  { quickshell -c hykr ipc call osd show "$kind" "$value" "$muted" >/dev/null 2>&1 & disown; }
exit 0
