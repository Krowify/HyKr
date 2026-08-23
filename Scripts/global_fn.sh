#!/usr/bin/env bash
# Shared lib sourced by every script in Scripts/. Callers set scrDir first:
#   scrDir="$(dirname "$(realpath "$0")")"
#   source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

set -e

repoDir="$(realpath "${scrDir}/..")"
dotsDir="${scrDir}/dots"
confDir="${repoDir}/Configs/configs"

print_log() {
    echo -e "[HyKr] $*"
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
