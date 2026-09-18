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

# Fail CLOSED.
#
# hyprlock's exit status used to be ignored entirely: `hyprlock` on its own
# line, then restore the bar. If hyprlock could not start at all -- a bad
# config, an EGL/GPU problem, a missing font -- this script returned cleanly
# and the session was simply never locked. That matters most on the path you
# cannot see happening: hypridle.conf sets
# `before_sleep_cmd = loginctl lock-session`, which routes here, so a
# hyprlock that fails to start means the laptop suspends unlocked and wakes
# unlocked.
#
# A clean unlock and a failed launch are told apart by how long hyprlock ran:
# nobody types a password in under LOCK_MIN_SECONDS, and a launch failure is
# effectively instant. A fast failure is retried a couple of times (the
# session-lock handshake can lose a race with a compositor that is still
# coming up); if it still will not hold, the session is terminated rather
# than left open on an unattended machine.
#
# Set HYKR_LOCK_NO_FAILCLOSED=1 if you would rather keep the session on a
# lock failure -- e.g. while debugging a hyprlock config.
LOCK_MIN_SECONDS=3
LOCK_ATTEMPTS=3

lock_held=0
for (( attempt = 1; attempt <= LOCK_ATTEMPTS; attempt++ )); do
    started=$SECONDS
    # Foreground on purpose: this returns when the session is unlocked.
    hyprlock
    rc=$?
    elapsed=$(( SECONDS - started ))

    if (( rc == 0 )) || (( elapsed >= LOCK_MIN_SECONDS )); then
        # Either a clean unlock, or hyprlock stayed up long enough that the
        # screen really was locked for that whole time.
        lock_held=1
        break
    fi

    echo "lock.sh: hyprlock exited ${rc} after ${elapsed}s (attempt ${attempt}/${LOCK_ATTEMPTS}) -- retrying" >&2
    sleep 1
done

if (( lock_held == 0 )); then
    echo "lock.sh: hyprlock will not stay up; refusing to leave the session unlocked." >&2
    if [[ "${HYKR_LOCK_NO_FAILCLOSED:-0}" == "1" ]]; then
        echo "lock.sh: HYKR_LOCK_NO_FAILCLOSED=1 -- leaving the session open anyway." >&2
        exit 1
    fi
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -u critical "HyKr" "hyprlock failed to start -- ending the session" || true
    # Blank the outputs first, so the desktop is not readable during the
    # second or two it takes logind to tear the session down.
    hyprctl dispatch 'hl.dsp.dpms({action = "off"})' >/dev/null 2>&1 || true
    loginctl terminate-session "${XDG_SESSION_ID:-self}" >/dev/null 2>&1 ||
        hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 || true
    exit 1
fi

restore_bar

# A shell that dies *because* of the unlock can take a moment to do it, so
# one check the instant hyprlock exits can see it still alive and do
# nothing. Check again a couple of seconds later; start_bar.sh is a no-op
# if the first call already sorted it out.
sleep 2
restore_bar
