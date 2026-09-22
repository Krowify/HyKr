#!/usr/bin/env bash
# Keeps avahi's bvnc/bssh/avahi-discover launchers out of wofi/rofi.
#
# avahi isn't in pkg_*.lst -- it comes in as a dependency, so it can't be
# uninstalled on its own. Shadowing the .desktop files from
# ~/.local/share/applications didn't reliably hide them from wofi, so tell
# pacman never to extract them instead (NoExtract in /etc/pacman.conf). That
# holds for every launcher and survives avahi upgrades. Idempotent.
#
# NoExtract only stops future extraction -- a reinstall or upgrade leaves any
# copy already on disk in place -- so existing ones are deleted here too.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

PACMAN_CONF="/etc/pacman.conf"
launchers=(
    usr/share/applications/avahi-discover.desktop
    usr/share/applications/bssh.desktop
    usr/share/applications/bvnc.desktop
)

if grep -q '^NoExtract.*avahi-discover\.desktop' "$PACMAN_CONF"; then
    print_log "pacman.conf already skips avahi's launchers"
else
    print_log "Adding a NoExtract line for avahi's launchers to ${PACMAN_CONF}"
    # pacman accumulates repeated NoExtract lines, so this never clobbers
    # one the user already has.
    sudo sed -i "/^\[options\]/a NoExtract = ${launchers[*]}" "$PACMAN_CONF"
fi

for f in "${launchers[@]}"; do
    if [ -e "/$f" ]; then
        print_log "Removing /$f"
        sudo rm -f "/$f"
    fi
done

# wofi keeps launched entries in its own cache and can list them from there.
rm -f "$HOME/.cache/wofi-drun"
