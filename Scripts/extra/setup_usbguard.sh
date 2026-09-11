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
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf > /dev/null

print_log "Enabling usbguard"
enable_service usbguard.service

print_log "usbguard is now enforcing. Anything plugged in from here on needs approval:"
print_log "  sudo usbguard list-devices      # see pending/blocked devices"
print_log "  sudo usbguard allow-device <N>  # approve one by its listed ID"
