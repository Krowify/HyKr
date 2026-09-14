#!/usr/bin/env bash
# Lock the session, and make sure the bar is back once you unlock.
#
# Every way of locking in this repo routes through here -- the Super+L
# keybind, wlogout's Lock button, quick_settings.sh's "Lock Screen", and
# hypridle's lock_cmd (which is also what `loginctl lock-session` and the
# before-suspend hook trigger). One path, so the unlock side below can't be
# skipped depending on how you happened to lock.
#
# Why the unlock side exists: hyprlock takes an exclusive ext-session-lock
# surface, and a Quickshell shell (`quickshell -c hyperspace`, `-c laptop`)
# does not always survive that -- come back from the lock screen and the
# dock can be gone, with nothing supervising it to bring it back. waybar
# themes are no different in principle; start_bar.sh handles either.
#
# start_bar.sh only starts what the ACTIVE theme asks for, and only if it
# isn't already running, so on a healthy unlock this is a no-op rather than
# a visible bar restart.
set -uo pipefail

BAR="$HOME/.config/hypr/start_bar.sh"

restore_bar() {
    [[ -x "$BAR" ]] || return 0
    "$BAR" >/dev/null 2>&1 || true
}

# Already locked: don't stack a second hyprlock on top of the first (which
# is what `pidof hyprlock || hyprlock` guarded against everywhere this
# script replaced). Nothing to restore either -- the instance already
# running owns that.
if pidof hyprlock >/dev/null 2>&1; then
    exit 0
fi

# Foreground on purpose: this returns when the session is unlocked.
hyprlock

restore_bar

# A shell that dies *because* of the unlock can take a moment to do it, so
# one check the instant hyprlock exits can see it still alive and do
# nothing. Check again a couple of seconds later; start_bar.sh is a no-op
# if the first call already sorted it out.
sleep 2
restore_bar
