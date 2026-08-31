#!/usr/bin/env bash
# Installs Configs/networkmanager/mac-randomize.conf as a NetworkManager
# conf.d drop-in (system-wide, needs sudo) so every WiFi connection uses a
# random MAC instead of the real hardware one.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

confSrc="${repoDir}/Configs/networkmanager/mac-randomize.conf"
confDst="/etc/NetworkManager/conf.d/mac-randomize.conf"

print_log "Installing NetworkManager MAC randomization drop-in"
sudo mkdir -p "$(dirname "$confDst")"
sudo cp "$confSrc" "$confDst"

if systemd_is_live && systemctl is-active --quiet NetworkManager.service; then
    print_log "Reloading NetworkManager to pick up the new config"
    sudo systemctl reload NetworkManager.service
else
    print_log "NetworkManager isn't running yet (fresh install) -- it'll pick up this config on first start."
fi

print_log "Done. Reconnect to WiFi (or reboot) for the randomized MAC to take effect."
