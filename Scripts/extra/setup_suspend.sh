#!/usr/bin/env bash
# Lid-close power management: make a closed lid stop eating the battery.
#
# Nothing in this repo configured this before. hypridle.conf's `general`
# block says "laptop lid close triggers systemd-logind's suspend directly",
# which is true -- logind's built-in default is HandleLidSwitch=suspend --
# but it leaves two things unhandled that decide whether a closed lid
# actually costs you anything:
#
#   1. WHICH suspend. Most laptops made since ~2019 ship firmware whose
#      only sleep state is s2idle ("modern standby"/S0ix): the kernel parks
#      userspace but the platform stays powered, relying on every device
#      reaching its own low-power state. One device that doesn't (a USB
#      dongle, a wifi card with a stale firmware, a discrete GPU that never
#      idles) and the machine sits in s2idle at several watts. That is the
#      "closed the lid at 90%, dead by lunchtime" case, and from the outside
#      it looks identical to suspend never happening. Where the firmware
#      also offers `deep` (real S3) but doesn't default to it, switching is
#      the single biggest win available.
#   2. HOW LONG. s2idle or S3, a suspended laptop still drains. The bound
#      on "I closed it Friday" is hibernation: suspend-then-hibernate sleeps
#      normally, then writes RAM to swap and powers off after a delay. This
#      is also what makes wlogout's Hibernate button work -- the layout has
#      shipped one since the beginning, and on a stock Arch install with no
#      resume= and no swap it fails silently.
#
# So: diagnose first, print what was found, then write explicit logind and
# sleep drop-ins for whatever this machine can actually do. Hibernation is
# only enabled once logind itself confirms it's possible -- an unbootable
# `suspend-then-hibernate` is worse than the drain it fixes, because the
# lid-close handler fails and the machine stays awake.
#
#   ./setup_suspend.sh            # diagnose, then apply
#   ./setup_suspend.sh --check    # diagnose only, write nothing
#   ./setup_suspend.sh --yes      # don't prompt (assume yes)

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

CHECK_ONLY=false
ASSUME_YES=false

usage() {
    cat <<'USAGE'
Usage: setup_suspend.sh [--check] [--yes]

  --check, -n   Diagnose only -- print the sleep state, lid config,
                inhibitors and hibernation readiness, and change nothing.
  --yes,   -y   Don't prompt; take the recommended answer.
USAGE
}

for arg in "$@"; do
    case "$arg" in
        --check|-n) CHECK_ONLY=true ;;
        --yes|-y) ASSUME_YES=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $arg"; usage; exit 1 ;;
    esac
done

# Non-interactive (piped, or run from a script) answers "no" rather than
# hanging on a read that nothing will ever type into. Every prompt here
# guards a change that has a safe skip, so no is always a valid answer.
confirm() {
    local reply
    $ASSUME_YES && return 0
    [[ -t 0 ]] || return 1
    read -rp "[HyKr] $1 [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

LOGIND_DROPIN="/etc/systemd/logind.conf.d/10-hykr-lid.conf"
SLEEP_DROPIN="/etc/systemd/sleep.conf.d/10-hykr-sleep.conf"
MEM_SLEEP_TMPFILES="/etc/tmpfiles.d/hykr-mem-sleep.conf"

# --------------------------------------------------- // Is this a laptop
# A desktop has no lid to close and no battery to flatten, and forcing
# `deep` on one that reports it does nothing useful. Bail out cleanly
# rather than writing lid config nothing will ever read -- install.sh runs
# this on every machine.
have_battery=false
for supply in /sys/class/power_supply/*; do
    [[ -r "${supply}/type" ]] || continue
    if [[ "$(cat "${supply}/type" 2>/dev/null || true)" == "Battery" ]]; then
        have_battery=true
    fi
done

have_lid=false
if [[ -d /proc/acpi/button/lid ]] && compgen -G "/proc/acpi/button/lid/*" >/dev/null; then
    have_lid=true
fi

if ! $have_battery && ! $have_lid; then
    print_log "No battery and no lid switch -- desktop, nothing to configure."
    exit 0
fi

# --------------------------------------------------- // What sleep states exist
# /sys/power/mem_sleep lists what `systemctl suspend` can use, with the
# active one in [brackets]: "[s2idle]" alone means modern-standby-only
# hardware, "s2idle [deep]" means real S3 is already in use.
mem_sleep_raw=""
if [[ -r /sys/power/mem_sleep ]]; then
    mem_sleep_raw="$(cat /sys/power/mem_sleep 2>/dev/null || true)"
fi

mem_sleep_active="$(grep -o '\[[a-z0-9_]*\]' <<<"${mem_sleep_raw}" | tr -d '[]' || true)"
has_deep=false
if grep -qw deep <<<"${mem_sleep_raw}"; then
    has_deep=true
fi

# --------------------------------------------------- // Can this machine hibernate
# logind's own CanHibernate is the answer that matters: it's the same check
# the lid handler runs, so agreeing with it is what keeps
# suspend-then-hibernate from failing at the moment the lid shuts. The
# individual facts below are gathered regardless -- when the answer is no,
# they're what tells you which piece is missing.
can_hibernate="unknown"
if systemd_is_live && command -v busctl &>/dev/null; then
    hibernate_reply="$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager CanHibernate 2>/dev/null || true)"
    case "${hibernate_reply}" in
        # "challenge" means possible but polkit wants authentication -- the
        # hardware/swap side is fine, which is all this decision needs.
        *'"yes"'*|*'"challenge"'*) can_hibernate="yes" ;;
        *'"na"'*|*'"no"'*) can_hibernate="no" ;;
    esac
fi

mem_total_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)"
swap_total_kb="$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)"
: "${mem_total_kb:=0}"
: "${swap_total_kb:=0}"

resume_dev=""
if [[ -r /sys/power/resume ]]; then
    resume_dev="$(cat /sys/power/resume 2>/dev/null || true)"
fi
# The kernel reports an unset resume device as 0:0, not as an empty file.
resume_configured=false
if [[ -n "${resume_dev}" && "${resume_dev}" != "0:0" ]]; then
    resume_configured=true
fi

# Fall back to the same two facts logind would weigh, for a chroot or a
# machine without busctl: swap big enough to hold RAM, and a kernel that
# knows where to read it back from.
if [[ "${can_hibernate}" == "unknown" ]]; then
    if $resume_configured && (( swap_total_kb > 0 )) && (( swap_total_kb * 4 >= mem_total_kb * 3 )); then
        can_hibernate="yes"
    else
        can_hibernate="no"
    fi
fi

# --------------------------------------------------- // Can it RESUME
# Hibernating and resuming are two different problems, and logind only
# answers the first. CanHibernate=yes with an unset /sys/power/resume is a
# real combination: writing the image needs swap, reading it back needs
# something at boot that knows where the image is. Three things can supply
# that, so look for all three rather than trusting the one sysfs file:
#
#   - resume= on the kernel command line (the classic route, needs
#     mkinitcpio's `resume` hook, or dracut, which ships resume support by
#     default)
#   - /sys/power/resume already populated (same thing, seen from the
#     running kernel, e.g. set by a rule or a systemd generator)
#   - systemd 255+ on EFI writing a HibernateLocation EFI variable at
#     hibernate time, which the `systemd` initramfs hook reads back. Here
#     /sys/power/resume legitimately reads 0:0 while resume works fine.
#
# Finding none of them doesn't prove resume is broken -- a UKI or a
# hand-rolled initramfs can do this in ways this check can't see -- so this
# warns and tells you how to test it, rather than refusing to configure.
cmdline_resume=false
if grep -qE '(^|[[:space:]])resume=' /proc/cmdline 2>/dev/null; then
    cmdline_resume=true
fi

efi_boot=false
if [[ -d /sys/firmware/efi ]]; then
    efi_boot=true
fi

# HOOKS can live in mkinitcpio.conf or any drop-in beside it.
mkinitcpio_hooks="$(cat /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/*.conf 2>/dev/null \
    | grep -E '^[[:space:]]*HOOKS=' || true)"
initramfs_resume_hook=false
initramfs_systemd_hook=false
if grep -qE '\bresume\b' <<<"${mkinitcpio_hooks}"; then
    initramfs_resume_hook=true
fi
if grep -qE '\bsystemd\b' <<<"${mkinitcpio_hooks}"; then
    initramfs_systemd_hook=true
fi
# dracut builds resume support in by default, so its presence counts as the
# initramfs side being handled.
if command -v dracut &>/dev/null; then
    initramfs_resume_hook=true
fi

systemd_version="$(systemctl --version 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1 || true)"
: "${systemd_version:=0}"

resume_route=""
if $resume_configured || $cmdline_resume; then
    if $initramfs_resume_hook || $initramfs_systemd_hook; then
        resume_route="resume= plus an initramfs that can use it"
    else
        resume_route="resume= is set, but no initramfs resume hook found"
    fi
elif $efi_boot && $initramfs_systemd_hook && (( systemd_version >= 255 )); then
    resume_route="EFI HibernateLocation (systemd ${systemd_version} + systemd initramfs hook)"
fi

# Walks through what THIS machine needs to resume, rather than printing the
# generic recipe: which swap it would use, the UUID (and offset, for a
# swapfile) that resume= wants, where the kernel command line actually lives
# on this bootloader, and whether the initramfs already handles resume.
# Prints commands, never runs them -- an edit to the kernel command line is
# the one change here that can leave a machine unbootable, and that belongs
# in your hands with the bootloader in front of you.
print_resume_recipe() {
    local swap_line swap_name swap_type swap_uuid swap_fstype swap_fs_uuid

    swap_line="$(swapon --show=NAME,TYPE --noheadings 2>/dev/null | head -1 || true)"
    swap_name="$(awk '{print $1}' <<<"${swap_line}")"
    swap_type="$(awk '{print $2}' <<<"${swap_line}")"

    print_log "  Wiring up resume on this machine:"

    if [[ -z "${swap_name}" ]]; then
        print_log "    No swap is active right now (swapon --show is empty), even though"
        print_log "    /proc/meminfo reports some. Sort that out first."
        return 0
    fi

    print_log ""
    print_log "    1. What resume= needs to point at"
    if [[ "${swap_type}" == "partition" ]]; then
        swap_uuid="$(lsblk -no UUID "${swap_name}" 2>/dev/null | head -1 || true)"
        print_log "       Swap partition: ${swap_name}"
        if [[ -n "${swap_uuid}" ]]; then
            print_log "       -> add to the kernel command line:  resume=UUID=${swap_uuid}"
        else
            print_log "       -> get its UUID:  sudo blkid -s UUID -o value ${swap_name}"
            print_log "          then add:      resume=UUID=<that-uuid>"
        fi
    else
        # A swapfile needs two things: the UUID of the filesystem holding it,
        # and where in that filesystem the file physically starts. The offset
        # is filesystem-specific and needs root to read, so hand over the
        # command rather than guessing a number.
        swap_fs_uuid="$(findmnt -no UUID -T "${swap_name}" 2>/dev/null || true)"
        swap_fstype="$(findmnt -no FSTYPE -T "${swap_name}" 2>/dev/null || true)"
        print_log "       Swapfile: ${swap_name} (on a ${swap_fstype:-unknown} filesystem)"
        print_log "       A swapfile needs BOTH the filesystem's UUID and the file's offset."
        if [[ -n "${swap_fs_uuid}" ]]; then
            print_log "       Filesystem UUID: ${swap_fs_uuid}"
        else
            print_log "       Filesystem UUID:  findmnt -no UUID -T ${swap_name}"
        fi
        if [[ "${swap_fstype}" == "btrfs" ]]; then
            print_log "       Offset:  sudo btrfs inspect-internal map-swapfile -r ${swap_name}"
        else
            print_log "       Offset:  sudo filefrag -v ${swap_name} | awk '\$1==\"0:\" {print \$4}' | tr -d '.'"
        fi
        print_log "       -> add to the kernel command line:"
        print_log "          resume=UUID=${swap_fs_uuid:-<fs-uuid>} resume_offset=<offset>"
    fi

    print_log ""
    print_log "    2. Where the kernel command line lives here"
    if [[ -f /etc/kernel/cmdline ]]; then
        print_log "       /etc/kernel/cmdline (unified kernel image) -- append it there,"
        print_log "       then rebuild:  sudo mkinitcpio -P"
    elif [[ -d /boot/loader/entries ]] && compgen -G "/boot/loader/entries/*.conf" >/dev/null; then
        print_log "       systemd-boot. Append to the 'options' line of your entry:"
        local entry
        for entry in /boot/loader/entries/*.conf; do
            print_log "         ${entry}"
        done
    elif [[ -f /boot/limine.conf ]] || [[ -f /boot/limine/limine.conf ]]; then
        print_log "       Limine -- append to the CMDLINE of your boot entry in limine.conf."
    elif [[ -f /etc/default/grub ]]; then
        print_log "       GRUB. Append inside the quotes of GRUB_CMDLINE_LINUX_DEFAULT in"
        print_log "       /etc/default/grub, then:  sudo grub-mkconfig -o /boot/grub/grub.cfg"
    else
        print_log "       Couldn't identify the bootloader -- add it wherever this system's"
        print_log "       kernel command line is defined (check /proc/cmdline for what's"
        print_log "       already there)."
    fi

    print_log ""
    print_log "    3. The initramfs side"
    if $initramfs_systemd_hook; then
        print_log "       Your HOOKS use the 'systemd' hook, which resumes on its own once"
        print_log "       resume= is on the command line. Nothing to add -- just rebuild:"
        print_log "         sudo mkinitcpio -P"
    elif $initramfs_resume_hook; then
        print_log "       The 'resume' hook is already in HOOKS. Rebuild after editing the"
        print_log "       command line:  sudo mkinitcpio -P"
    else
        print_log "       Add 'resume' to HOOKS in /etc/mkinitcpio.conf, after 'block' and"
        print_log "       before 'filesystems', then:  sudo mkinitcpio -P"
        if [[ -n "${mkinitcpio_hooks}" ]]; then
            print_log "       Current: ${mkinitcpio_hooks}"
        fi
    fi

    print_log ""
    print_log "    4. Reboot (the command line only changes at boot), then re-run this"
    print_log "       script -- it should report a resume route, and 'sudo systemctl"
    print_log "       hibernate' should bring your session back."
}

kb_to_gib() {
    awk -v kb="$1" 'BEGIN { printf "%.1f", kb / 1048576 }'
}

# --------------------------------------------------- // Report
print_log ""
print_log "--- Suspend diagnosis -------------------------------------------"
if [[ -n "${mem_sleep_raw}" ]]; then
    print_log "Sleep states offered by firmware : ${mem_sleep_raw}"
    case "${mem_sleep_active}" in
        deep)   print_log "  Currently using 'deep' (S3) -- the low-drain one." ;;
        s2idle) if $has_deep; then
                    print_log "  Currently using 's2idle' even though 'deep' is available."
                    print_log "  This is the usual cause of a laptop that dies with the lid shut."
                else
                    print_log "  s2idle only -- this firmware offers no S3 state. Drain while"
                    print_log "  suspended is whatever the platform manages on its own, so"
                    print_log "  hibernation is the only hard bound available."
                fi ;;
        *)      print_log "  Active state: ${mem_sleep_active:-unknown}" ;;
    esac
else
    print_log "Sleep states offered by firmware : /sys/power/mem_sleep unreadable"
fi

print_log "RAM / swap                       : $(kb_to_gib "${mem_total_kb}") GiB / $(kb_to_gib "${swap_total_kb}") GiB"
print_log "Kernel resume device             : ${resume_dev:-unset}"
print_log "Hibernation possible             : ${can_hibernate}"
if [[ "${can_hibernate}" == "yes" ]]; then
    print_log "Resume after hibernation         : ${resume_route:-no route found}"
    if [[ -z "${resume_route}" ]]; then
        print_log "  Hibernation can WRITE the image but nothing here shows how the"
        print_log "  machine would read it back at boot: no resume= on the kernel"
        print_log "  command line, /sys/power/resume unset, and no systemd-on-EFI"
        print_log "  route either. If that's right, hibernating powers the machine"
        print_log "  off and the next boot is a cold one -- the battery is saved,"
        print_log "  the open session isn't."
        print_log "  Test it before trusting it: save your work, then"
        print_log "    sudo systemctl hibernate"
        print_log "  power the machine back on, and see whether the session returns."
        print_log ""
        print_resume_recipe
    fi
fi

if systemd_is_live && command -v systemd-analyze &>/dev/null; then
    lid_now="$(systemd-analyze cat-config systemd/logind.conf 2>/dev/null \
        | grep -Ei '^\s*Handle(LidSwitch|LidSwitchExternalPower|LidSwitchDocked)=' || true)"
    if [[ -n "${lid_now}" ]]; then
        print_log "Lid settings currently set       :"
        while IFS= read -r line; do
            print_log "  ${line}"
        done <<<"${lid_now}"
    else
        print_log "Lid settings currently set       : none (logind defaults: suspend)"
    fi
fi

# A *block* inhibitor on sleep or handle-lid-switch is the other way a
# closed lid does nothing. Idle inhibitors don't apply -- logind's
# LidSwitchIgnoreInhibited defaults to yes, which overrides those
# specifically for the lid.
if systemd_is_live && command -v systemd-inhibit &>/dev/null; then
    blockers="$(systemd-inhibit --list --no-pager 2>/dev/null \
        | grep -E 'sleep|handle-lid-switch' | grep -w block || true)"
    if [[ -n "${blockers}" ]]; then
        print_log "Something is BLOCKING sleep:"
        while IFS= read -r line; do
            print_log "  ${line}"
        done <<<"${blockers}"
        print_log "  A block inhibitor on sleep/handle-lid-switch makes a closed lid"
        print_log "  do nothing at all. Quit that program (or fix what's holding the"
        print_log "  lock) -- no amount of config below overrides it."
    else
        print_log "Sleep inhibitors                 : none blocking"
    fi
fi

if systemd_is_live; then
    lid_log="$(journalctl -b -u systemd-logind --grep 'Lid (opened|closed)' -n 4 --no-pager -q 2>/dev/null || true)"
    if [[ -n "${lid_log}" ]]; then
        print_log "Last lid events this boot:"
        while IFS= read -r line; do
            print_log "  ${line}"
        done <<<"${lid_log}"
    fi
fi
print_log "-----------------------------------------------------------------"
print_log ""

if $CHECK_ONLY; then
    print_log "--check: nothing written."
    exit 0
fi

if [[ "${can_hibernate}" == "yes" && -z "${resume_route}" ]]; then
    # Still worth enabling: on s2idle-only firmware a bounded drain is the
    # whole point, and a cold boot is a far smaller loss than a flat
    # battery. But say plainly what the unverified half costs.
    print_log ""
    print_log "NOTE: enabling suspend-then-hibernate with resume unverified (see above)."
    print_log "  Worst case the lid-close saves the battery but not the session."
    print_log "  'sudo systemctl hibernate' once, by hand, settles it either way."
    print_log ""
fi

# --------------------------------------------------- // Lid handling
# Explicit beats inherited here. logind's default really is suspend, but
# the default is also what a distro update, a desktop portal package or a
# stray drop-in can change underneath you -- and on this machine the lid is
# the ONLY thing that ever suspends it (hypridle locks and blanks on idle,
# it doesn't sleep). Pin all three cases:
#   HandleLidSwitch              -- on battery, the case this script exists for
#   HandleLidSwitchExternalPower -- plugged in: still suspend, but no need to
#                                   hibernate, the battery isn't the clock
#   HandleLidSwitchDocked        -- external monitor attached: closing the lid
#                                   to use the laptop as a desk machine must
#                                   not put it to sleep
if [[ "${can_hibernate}" == "yes" ]]; then
    lid_action="suspend-then-hibernate"
else
    lid_action="suspend"
fi

print_log "Writing lid handling -> ${LOGIND_DROPIN} (HandleLidSwitch=${lid_action})"
sudo mkdir -p "$(dirname "${LOGIND_DROPIN}")"
sudo tee "${LOGIND_DROPIN}" > /dev/null <<EOF
# Managed by HyKr -- Scripts/extra/setup_suspend.sh. Re-run that script
# after changing swap or hibernation setup; delete this file to go back to
# logind's built-in defaults.
[Login]
HandleLidSwitch=${lid_action}
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF

# --------------------------------------------------- // Hibernation delay
if [[ "${can_hibernate}" == "yes" ]]; then
    print_log "Writing hibernation delay -> ${SLEEP_DROPIN} (suspend for 45min, then hibernate)"
    sudo mkdir -p "$(dirname "${SLEEP_DROPIN}")"
    sudo tee "${SLEEP_DROPIN}" > /dev/null <<'EOF'
# Managed by HyKr -- Scripts/extra/setup_suspend.sh.
[Sleep]
# How long suspend-then-hibernate stays merely suspended before writing RAM
# to swap and powering off. 45 minutes keeps the instant-resume behaviour
# for a lunch break or a walk between rooms, and bounds an overnight or
# over-the-weekend lid-close at roughly one suspend-hour of drain no matter
# how badly the platform handles s2idle.
#
# systemd 254 and newer otherwise pick this delay from the battery's own
# discharge estimate (SuspendEstimationSec); setting it explicitly is the
# deterministic version of the same idea, and works the same on older
# systemd, which has no estimator at all.
HibernateDelaySec=45min
EOF
else
    print_log "Hibernation is NOT available -- lid close will plain suspend."
    print_log "  Without it, a suspended laptop drains until the battery is gone;"
    print_log "  how fast depends entirely on the firmware (see the sleep state above)."
    print_log "  wlogout's Hibernate button is also inert until this is sorted."
    print_log "  To enable it:"
    if (( swap_total_kb == 0 )); then
        print_log "    1. Add swap at least the size of RAM ($(kb_to_gib "${mem_total_kb}") GiB) --"
        print_log "       a swapfile is fine: see 'man mkswap' / the Arch wiki's"
        print_log "       Power management/Suspend and hibernate page."
    elif (( swap_total_kb * 4 < mem_total_kb * 3 )); then
        print_log "    1. Grow swap -- $(kb_to_gib "${swap_total_kb}") GiB for $(kb_to_gib "${mem_total_kb}") GiB of RAM is"
        print_log "       too small to hold a hibernation image reliably."
    else
        print_log "    1. Swap size looks sufficient ($(kb_to_gib "${swap_total_kb}") GiB)."
    fi
    if ! $resume_configured; then
        print_log "    2. Point the kernel at it: add resume=UUID=<swap-uuid> (plus"
        print_log "       resume_offset= for a swapfile) to the kernel command line."
    else
        print_log "    2. Resume device is already set (${resume_dev})."
    fi
    print_log "    3. Make the initramfs able to resume: mkinitcpio's 'resume' hook"
    print_log "       after 'block' and before 'filesystems' (busybox-based HOOKS),"
    print_log "       or nothing at all if you use the 'systemd' hook -- it handles"
    print_log "       resume itself. Then: sudo mkinitcpio -P"
    print_log "    Re-run this script afterwards and it'll switch the lid over to"
    print_log "    suspend-then-hibernate."
fi

# --------------------------------------------------- // s2idle -> deep
# Only offered when the firmware actually lists `deep`. Prompted rather than
# applied, and applied through tmpfiles.d rather than a kernel parameter,
# because a handful of machines advertise S3 and then resume from it badly
# (black screen, dead keyboard). A tmpfiles drop-in is undone with one rm
# from a TTY; a bad kernel parameter needs the bootloader's edit prompt.
if $has_deep && [[ "${mem_sleep_active}" != "deep" ]]; then
    print_log ""
    print_log "This firmware offers 'deep' (S3) but suspends with s2idle."
    print_log "Switching cuts suspend drain dramatically on most laptops. On a few,"
    print_log "S3 resume is buggy -- if the machine comes back to a black screen,"
    print_log "undo it from a TTY with: sudo rm ${MEM_SLEEP_TMPFILES}"
    if confirm "Use 'deep' sleep instead of s2idle?"; then
        sudo mkdir -p "$(dirname "${MEM_SLEEP_TMPFILES}")"
        # mem_sleep resets to the firmware default on every boot, so this
        # has to be re-applied each time -- tmpfiles.d's `w` does exactly
        # that, at boot, without a unit to maintain.
        sudo tee "${MEM_SLEEP_TMPFILES}" > /dev/null <<'EOF'
# Managed by HyKr -- Scripts/extra/setup_suspend.sh. Selects the deep (S3)
# sleep state at every boot; /sys/power/mem_sleep otherwise reverts to the
# firmware's default (usually s2idle) each time. Delete this file to go back.
w /sys/power/mem_sleep - - - - deep
EOF
        if systemd_is_live; then
            # Apply now as well, so the very next lid close benefits rather
            # than the one after the next reboot.
            echo deep | sudo tee /sys/power/mem_sleep > /dev/null || {
                print_log "WARNING: couldn't switch /sys/power/mem_sleep right now -- it'll"
                print_log "  take effect on the next boot via ${MEM_SLEEP_TMPFILES}."
            }
        fi
        print_log "Sleep state set to deep."
    else
        print_log "Left on s2idle."
    fi
fi

# --------------------------------------------------- // Apply
# Deliberately not restarting systemd-logind: on a live session that can
# take the session (and every process in it) with it. A reload picks the
# drop-in up where the unit supports one, and a reboot always does.
if systemd_is_live; then
    if sudo systemctl reload systemd-logind.service 2>/dev/null; then
        print_log "Reloaded systemd-logind -- lid handling is live now."
    else
        print_log "systemd-logind can't reload in place here; the new lid handling"
        print_log "  applies after the next reboot (or a logout + 'systemctl restart"
        print_log "  systemd-logind' from a TTY, which ends the current session)."
    fi
    # sleep.conf.d is read fresh at each sleep, so there is nothing to
    # reload for the hibernation delay -- it's already in effect.
else
    print_log "No live systemd here (chroot) -- both drop-ins apply on first boot."
fi

print_log ""
print_log "Done. Check it worked: close the lid, wait a minute, open it and run"
print_log "  journalctl -b -u systemd-logind --grep 'Lid closed'"
print_log "  journalctl -b --grep 'PM: suspend (entry|exit)'"
print_log "To measure the real cost, note /sys/class/power_supply/BAT*/capacity"
print_log "before and after a long lid-closed stretch."
