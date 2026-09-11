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

# Refuse to saw off the branch we're sitting on. install.sh already skips
# this step over SSH, but this script is also documented as runnable on its
# own -- and "I disabled sshd from an SSH session" is unrecoverable without
# physical access to the machine. HYKR_FORCE_DISABLE_SSHD=1 overrides, for
# the case where you genuinely mean it (e.g. you're about to be at the
# console anyway).
if [[ "${HYKR_FORCE_DISABLE_SSHD:-}" != "1" ]] \
   && [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" || "${HYKR_OVER_SSH:-0}" == "1" ]]; then
    print_log "Refusing to disable sshd: this session came in over SSH, and stopping"
    print_log "sshd would drop it. Re-run this at the machine's own console, or with"
    print_log "HYKR_FORCE_DISABLE_SSHD=1 if you're sure."
    exit 0
fi

if systemctl is-enabled --quiet sshd.service 2>/dev/null; then
    print_log "sshd is enabled — disabling it (not used for inbound access to this machine)"
    sudo systemctl disable --now sshd.service
else
    print_log "sshd isn't enabled — nothing to do"
fi
