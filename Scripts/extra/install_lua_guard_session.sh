#!/usr/bin/env bash
# Installs a second SDDM session, "Hyprland (HyKr)", that quarantines any
# hyprmod-regenerated hyprland.lua *before* Hyprland's own launcher runs --
# see Configs/configs/hypr/start-hyprland-hykr.sh for why an exec-once
# inside hyprland.conf can't do this early enough on its own. Never touches
# the stock hyprland/hyprland-uwsm session entries, so a `pacman -Syu` of
# the hyprland package can't clobber this.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

wrapperSrc="${repoDir}/Configs/configs/hypr/start-hyprland-hykr.sh"
wrapperDst="/usr/local/bin/start-hyprland-hykr"
desktopSrc="${repoDir}/Configs/configs/hypr/hyprland-hykr.desktop"
desktopDst="/usr/share/wayland-sessions/hyprland-hykr.desktop"

print_log "Installing Hyprland (HyKr) SDDM session (lua-config guard)"

sudo install -Dm755 "$wrapperSrc" "$wrapperDst"
sudo install -Dm644 "$desktopSrc" "$desktopDst"

print_log "Done. Pick 'Hyprland (HyKr)' as the session at the SDDM login screen."
