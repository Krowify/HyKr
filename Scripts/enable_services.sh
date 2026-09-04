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

print_log "Enabling NetworkManager"
enable_service NetworkManager.service

print_log "Enabling Bluetooth"
enable_service bluetooth.service

print_log "Enabling power-profiles-daemon"
enable_service power-profiles-daemon.service
