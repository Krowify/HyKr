#!/usr/bin/env bash
# Enables the system services the desktop actually needs running after
# reboot. Not optional -- without these, a fresh install boots to a TTY
# (no sddm), no network, and no bluetooth, no matter what packages
# got installed.

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

print_log "Enabling SDDM (login manager)"
sudo systemctl enable --now sddm.service

print_log "Enabling NetworkManager"
sudo systemctl enable --now NetworkManager.service

print_log "Enabling Bluetooth"
sudo systemctl enable --now bluetooth.service
