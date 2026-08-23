#!/usr/bin/env bash
# System hardening: firewalld, sysctl anti-spoofing, fail2ban. Same overall
# posture as arch-install's stage-4 (deny incoming / allow outgoing / log /
# fail2ban / sysctl), adapted to firewalld's zone model instead of ufw --
# chosen deliberately over ufw for its NetworkManager zone integration,
# since this runs on both a desktop and a laptop that moves between networks.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

if ! command -v firewall-cmd &>/dev/null; then
    print_log "firewalld not installed — install it first: sudo pacman -S firewalld"
    exit 1
fi

print_log "Enabling firewalld"
enable_service firewalld

# firewall-cmd is only a client to the running firewalld daemon -- every
# invocation below (including --permanent ones) needs to reach it over
# D-Bus, which isn't possible inside arch-chroot pre-reboot (nothing
# started it). Configuring the live zone has to wait until then.
if systemd_is_live; then
    print_log "Setting default zone to 'public' (applies to any network firewalld hasn't been told to trust)"
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
else
    print_log "Skipping live firewalld zone config — no live systemd here (chroot) to reach the daemon."
    print_log "Re-run this script after your first reboot to finish configuring firewalld."
fi

# --- sysctl anti-spoofing hardening (firewall-agnostic, ported from
# arch-install's stage 4)
print_log "Writing sysctl hardening rules"
cat <<'EOF' | sudo tee /etc/sysctl.d/90-hardening.conf > /dev/null
# Enable source route verification (anti IP-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Log packets with impossible addresses (martians)
net.ipv4.conf.all.log_martians = 1
EOF
sudo sysctl --system

print_log "Writing /etc/host.conf (anti IP-spoofing)"
cat <<EOF | sudo tee /etc/host.conf > /dev/null
order bind,hosts
multi on
EOF

# --- fail2ban: inert until sshd is actually enabled and generating auth
# logs, so it's safe to configure regardless of whether you use SSH.
print_log "Configuring fail2ban"
sudo mkdir -p /etc/fail2ban
cat <<'EOF' | sudo tee /etc/fail2ban/jail.local > /dev/null
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
EOF
enable_service fail2ban

if systemd_is_live; then
    print_log "Firewall hardened. Current zone config:"
    sudo firewall-cmd --list-all
else
    print_log "firewalld/fail2ban are enabled and will start on first real boot;"
    print_log "live zone config isn't available until then (see note above)."
fi

print_log "NOTE: 'public' (restrictive) is the default for any network firewalld"
print_log "hasn't been told to trust. On the laptop, once connected to a network"
print_log "you actually trust (home/work Wi-Fi), assign it a looser zone with:"
print_log "  sudo firewall-cmd --zone=home --change-interface=<iface> --permanent"
print_log "  sudo firewall-cmd --reload"
