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

# True when a live systemd manager is actually running (PID 1) -- false
# inside arch-chroot before the first boot into the new system. This is
# systemd's own canonical marker for that (used by distro packaging
# scripts to decide the same enable-vs-enable+start question).
systemd_is_live() {
    [[ -d /run/systemd/system ]]
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
