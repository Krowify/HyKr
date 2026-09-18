#!/usr/bin/env bash
# Idle sleep, but only when this machine is actually eating its battery.
#
# Why this exists: nothing else in HyKr ever suspends. logind's lid switch was
# the only path, and setup_suspend.sh deliberately leaves
# HandleLidSwitchDocked=ignore so the laptop can drive an external monitor with
# the lid shut. logind counts ANY connected external display as "docked", so a
# single HDMI cable routes every lid close through that ignore -- and hypridle
# on its own only notifies, locks, and blanks the screen via DPMS. A laptop at
# a desk with the lid closed therefore ran until the battery was gone, behind a
# dark screen that looked exactly like sleep.
#
# So: hypridle calls this at its longest timeout. On the charger, or on a
# desktop, it does nothing -- the desk-machine-with-the-lid-shut workflow is
# the whole reason Docked=ignore is there and this must not break it. Off the
# charger it sleeps the machine regardless of what the lid did.
#
# It asks for suspend-then-hibernate where that is possible, not plain suspend:
# the hibernate half is a property of the sleep operation, so `systemctl
# suspend` here would bound nothing and we would be back to s2idle draining
# overnight.
#
#   idle_sleep.sh                     general backstop (hypridle's long timeout)
#   idle_sleep.sh --lid-closed-only   only act if the lid is physically shut
#
# The --lid-closed-only mode exists because the lid case deserves a much
# shorter fuse than "you walked away with the laptop open". With no external
# display logind handles a closed lid the instant it shuts, so that mode never
# fires; with one attached logind ignores the lid completely, and this is the
# only thing that will ever sleep the machine. Waiting the full general timeout
# there would mean a lid closed off the charger still sat awake for an hour.
#
# Always exits 0 -- hypridle should never see a failure from an idle hook.
set -uo pipefail

LID_ONLY=false
case "${1:-}" in
    --lid-closed-only) LID_ONLY=true ;;
    "") ;;
    *) echo "idle_sleep.sh: unknown argument '$1'" >&2; exit 0 ;;
esac

log() { echo "idle_sleep.sh: $*" >&2; }

# --------------------------------------------------- // Desktop?
# Same test setup_suspend.sh uses to decide a machine has nothing to protect.
have_battery=false
for supply in /sys/class/power_supply/*; do
    [[ -r "${supply}/type" ]] || continue
    if [[ "$(cat "${supply}/type" 2>/dev/null || true)" == "Battery" ]]; then
        have_battery=true
        break
    fi
done
$have_battery || exit 0

# --------------------------------------------------- // Lid shut?
# Only asked in --lid-closed-only mode. Not every machine exposes this, and a
# lid whose state cannot be read is NOT assumed closed -- suspending a laptop
# someone is actively using because a sysfs file is missing would be a far
# worse failure than waiting for the general timeout, which still covers it.
lid_is_closed() {
    local f state found=false
    for f in /proc/acpi/button/lid/*/state; do
        [[ -r "$f" ]] || continue
        found=true
        state="$(cat "$f" 2>/dev/null || true)"
        [[ "${state}" == *closed* ]] && return 0
    done
    $found || log "no readable lid state -- leaving this to the general timeout"
    return 1
}

if $LID_ONLY && ! lid_is_closed; then
    exit 0
fi

# --------------------------------------------------- // Actually on battery?
# The battery's own status is the direct answer to "is this draining right
# now", and beats inferring it from an AC adapter's `online`: a USB-C dock can
# report online while delivering no power. Fall back to the mains reading only
# when no battery will say.
on_battery() {
    local supply status online saw_mains=false
    for supply in /sys/class/power_supply/*; do
        [[ -r "${supply}/type" ]] || continue
        case "$(cat "${supply}/type" 2>/dev/null || true)" in
            Battery)
                status="$(cat "${supply}/status" 2>/dev/null || true)"
                [[ "${status}" == "Discharging" ]] && return 0
                ;;
            *)
                online="$(cat "${supply}/online" 2>/dev/null || true)"
                [[ -n "${online}" ]] && saw_mains=true
                [[ "${online}" == "1" ]] && return 1
                ;;
        esac
    done
    # Every mains supply said 0 -- unplugged, even if no battery said so.
    $saw_mains && return 0
    # Nothing would answer. Don't suspend on a guess.
    return 1
}

if ! on_battery; then
    exit 0
fi

# --------------------------------------------------- // Which sleep
# Ask logind rather than re-deriving it: it is the same check that decides
# whether the lid handler's suspend-then-hibernate would work, so the idle path
# and the lid path can't disagree.
action="suspend"
if command -v busctl >/dev/null 2>&1; then
    reply="$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager CanHibernate 2>/dev/null || true)"
    case "${reply}" in
        *'"yes"'*|*'"challenge"'*) action="suspend-then-hibernate" ;;
    esac
fi

if $LID_ONLY; then
    log "lid shut and on battery -- ${action}"
else
    log "idle on battery -- ${action}"
fi
# A block inhibitor on sleep (a running backup, a VM) makes this fail, which is
# correct: something asked not to be slept and this is a backstop, not an
# override. hypridle will call again at the next timeout.
systemctl "${action}" || log "${action} refused (inhibitor?) -- leaving the machine awake"

exit 0
