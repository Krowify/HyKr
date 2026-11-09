#!/usr/bin/env bash
# Open, close or toggle one of the HyKr desktop shell's surfaces:
#
#   hykr.sh launcher            (Super+Tab)
#   hykr.sh clipboard           (Super+V)
#   hykr.sh control             (Super+M, Super+S)
#   hykr.sh wallpaper           (Super+Shift+W)
#   hykr.sh themes              (Super+Shift+T)
#   hykr.sh audio | bluetooth | network   (the bars' volume / Bluetooth /
#                                          network icons)
#   hykr.sh <target> open|close|toggle
#   hykr.sh wallpaper forTheme <theme-id>   (extra arguments are passed on)
#
# Each is an IpcHandler target in quickshell/hykr/shell.qml. The shell is
# meant to be running already (start_bar.sh starts it at login), which is
# what makes these instant; if it isn't -- a keypress in the first second
# after login, or it crashed -- this starts it and tries again rather than
# making the key do nothing.
set -uo pipefail

target="${1:-}"
fn="${2:-toggle}"
[[ -n "$target" ]] || { echo "usage: hykr.sh <target> [toggle|open|close|<function> <args>...]" >&2; exit 2; }
args=("${@:3}")

command -v quickshell >/dev/null 2>&1 || { echo "hykr.sh: quickshell is not installed" >&2; exit 1; }

call() {
  quickshell -c hykr ipc call "$target" "$fn" "${args[@]}" >/dev/null 2>&1
}

call && exit 0

# Not reachable: start it (with start_bar.sh's start-up check and on-screen
# error if its QML fails to load) and retry for a few seconds.
"$HOME/.config/hypr/start_bar.sh" --desktop >/dev/null 2>&1 || true
for _ in {1..20}; do
  sleep 0.15
  call && exit 0
done

echo "hykr.sh: the desktop shell is not answering -- see ${XDG_RUNTIME_DIR:-$HOME/.cache}/hykr-desktop.log" >&2
exit 1
