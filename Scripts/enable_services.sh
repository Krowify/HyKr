#!/usr/bin/env bash
# Enables the system services the desktop actually needs running after
# reboot. Not optional -- without these, a fresh install boots to a TTY
# (no sddm), no network, and no bluetooth, no matter what packages
# got installed.

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

print_log "Enabling SDDM (login manager)"
enable_service sddm.service

# NetworkManager shares the machine badly with the other network stacks.
# A very common Arch starting point (archinstall's minimal profile, or any
# iwd-based setup) leaves iwd and/or systemd-networkd enabled, and turning
# NetworkManager on next to them produces a Wi-Fi card that appears to
# vanish:
#   - iwd defaults to UseDefaultInterface=false, meaning it DESTROYS the
#     driver's default wlan0 at startup and creates its own netdev -- then
#     takes that netdev with it when it stops. The driver only creates the
#     default interface at module load, so after stopping iwd you are left
#     with a registered PHY (visible in `rfkill list`) and no interface at
#     all for NetworkManager to manage. `iw phy phy0 interface add wlan0
#     type managed` recreates it without a reboot.
#   - systemd-networkd will fight NetworkManager over every link it has a
#     .network file for.
# Warn rather than disable: tearing down whatever is currently carrying
# this machine's connection mid-install is not this script's call.
warn_conflicting_network_stack() {
    systemd_is_live || return 0

    local conflicting=() svc
    for svc in iwd.service systemd-networkd.service; do
        if [[ "$(systemctl is-enabled "$svc" 2>/dev/null || true)" == "enabled" ]]; then
            conflicting+=("$svc")
        fi
    done

    [[ ${#conflicting[@]} -gt 0 ]] || return 0

    print_log "WARNING: enabled alongside NetworkManager: ${conflicting[*]}"
    print_log "  These conflict with NetworkManager and can leave Wi-Fi with no"
    print_log "  usable interface (see the comment above this check). To hand the"
    print_log "  network over to NetworkManager:"
    for svc in "${conflicting[@]}"; do
        print_log "    sudo systemctl disable --now ${svc}"
    done
    print_log "  If Wi-Fi is missing from 'nmcli device status' afterwards but"
    print_log "  'rfkill list' still shows the PHY, recreate the interface with:"
    print_log "    sudo iw phy phy0 interface add wlan0 type managed"
}

print_log "Enabling NetworkManager"
warn_conflicting_network_stack
enable_service NetworkManager.service

print_log "Enabling Bluetooth"
enable_service bluetooth.service

print_log "Enabling power-profiles-daemon"
enable_service power-profiles-daemon.service
