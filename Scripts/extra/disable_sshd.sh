#!/usr/bin/env bash
# Disables sshd if it's enabled -- less attack surface on a machine that
# isn't actually used for inbound SSH. Safe to run even if openssh isn't
# installed at all (systemctl just reports not-found, nothing to do), and
# fully reversible: `sudo systemctl enable --now sshd` brings it back.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

if systemctl is-enabled --quiet sshd.service 2>/dev/null; then
    print_log "sshd is enabled — disabling it (not used for inbound access to this machine)"
    sudo systemctl disable --now sshd.service
else
    print_log "sshd isn't enabled — nothing to do"
fi
