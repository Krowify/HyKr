#!/usr/bin/env bash
# Installs usbguard and generates a baseline policy that allow-lists every
# USB device currently connected (keyboard, trackpad, YubiKey, etc.), then
# enables enforcement -- anything plugged in AFTER this point needs manual
# approval instead of just working.
#
# SAFETY: the policy is generated from whatever is plugged in at the
# moment this runs -- if your keyboard/trackpad aren't connected when
# this generates the policy (e.g. run over a non-USB remote session),
# usbguard will block them on the next boot. If that happens: boot to a
# TTY/recovery shell and run `sudo systemctl disable --now usbguard`.
# This is exactly why install.sh only offers this as an opt-in prompt,
# unlike the firewall/MAC-randomization steps.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

sudo pacman -S --needed --noconfirm usbguard

print_log "Generating a policy from every USB device currently connected"
sudo mkdir -p /etc/usbguard

# `tee` creates with the caller's umask, i.e. 0644 -- world-readable. The
# generated policy enumerates every USB device on the machine with its vendor
# and product IDs and, for most of them, its serial number (YubiKeys, phones,
# external drives): a hardware fingerprint of this laptop that no local user
# needs to be able to read. usbguard's own packaging ships rules.conf as
# 0600 root:root, so match that -- and set the mode BEFORE the policy is
# written, so it is never briefly world-readable in between.
sudo install -o root -g root -m 0600 /dev/null /etc/usbguard/rules.conf
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf > /dev/null
sudo chmod 0600 /etc/usbguard/rules.conf

print_log "Enabling usbguard"
enable_service usbguard.service

print_log "usbguard is now enforcing. Anything plugged in from here on needs approval:"
print_log "  sudo usbguard list-devices      # see pending/blocked devices"
print_log "  sudo usbguard allow-device <N>  # approve one by its listed ID"
