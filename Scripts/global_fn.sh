#!/usr/bin/env bash
# Shared lib sourced by every script in Scripts/. Callers set scrDir first:
#   scrDir="$(dirname "$(realpath "$0")")"
#   source "${scrDir}/global_fn.sh" || {
#       echo "Error: unable to source ${scrDir}/global_fn.sh"
#       ls -la "${scrDir}/global_fn.sh" 2>&1
#       exit 1
#   }

set -e

repoDir="$(realpath "${scrDir}/..")"
dotsDir="${scrDir}/dots"
confDir="${repoDir}/Configs/configs"

print_log() {
    echo -e "[HyKr] $*"
}

# True when NOT running inside a chroot -- false inside arch-chroot before
# the first boot into the new system. Checking for /run/systemd/system
# directly is NOT reliable here: arch-chroot sets up /run as part of
# entering the chroot (bind-mounted from the live ISO host, which is
# itself running systemd), so that directory can exist even though nothing
# is managing services for the new install yet. systemd-detect-virt
# --chroot is systemd's own purpose-built check for this (compares / to
# /proc/1/root), unaffected by that mount.
systemd_is_live() {
    if command -v systemd-detect-virt &>/dev/null; then
        ! systemd-detect-virt --chroot --quiet
    else
        [[ -d /run/systemd/system ]]
    fi
}

# Enable a systemd service, starting it now only if a live systemd manager
# is actually running (see systemd_is_live). Inside a chroot,
# `systemctl ... --now` fails outright (nothing to start against), so this
# falls back to enable-only -- the unit still starts on first real boot.
enable_service() {
    local svc="$1"
    if systemd_is_live; then
        sudo systemctl enable --now "${svc}"
    else
        sudo systemctl enable "${svc}"
        print_log "${svc} enabled but not started (no live systemd here) — it'll start on first real boot."
    fi
}

# Symlink $1 (repo path) to $2 (home path), backing up a pre-existing real file/dir first.
link_dot() {
    local src="$1" dst="$2"

    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        print_log "Backing up existing ${dst} -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    print_log "Linked ${dst} -> ${src}"
}
