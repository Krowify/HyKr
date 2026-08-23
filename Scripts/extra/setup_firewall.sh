#!/usr/bin/env bash
# Firewall hardening via firewalld: deny incoming by default, allow
# outgoing, log denials. Same posture as ufw setups in other Arch
# dotfiles repos (e.g. tiesen243/dotfiles), adapted to firewalld's
# zone model since that's what's installed here instead of ufw.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

if ! command -v firewall-cmd &>/dev/null; then
    print_log "firewalld not installed — install it first: sudo pacman -S firewalld"
    exit 1
fi

print_log "Enabling firewalld"
sudo systemctl enable --now firewalld

print_log "Setting default zone to 'public'"
sudo firewall-cmd --set-default-zone=public

print_log "Removing default-enabled services from the public zone (ssh, mdns, samba-client, dhcpv6-client)"
print_log "If you SSH into this machine or use LAN file sharing, re-add what you need — see the README note"
for svc in ssh mdns samba-client dhcpv6-client; do
    sudo firewall-cmd --zone=public --remove-service="$svc" --permanent 2>/dev/null
done

print_log "Logging denied packets"
sudo firewall-cmd --set-log-denied=all

print_log "Reloading firewalld"
sudo firewall-cmd --reload

print_log "Firewall hardened. Current zone config:"
sudo firewall-cmd --list-all
