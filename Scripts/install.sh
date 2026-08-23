#!/usr/bin/env bash
# Main entrypoint: preflight -> install packages -> link dots -> optional
# SDDM theme + firewall hardening. Run from anywhere: ~/HyKr/Scripts/install.sh

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

pkg_names() {
    grep -vE '^\s*#|^\s*$' "$1" | awk '{print $1}'
}

# --------------------------------------------------- // Preflight
if ! command -v pacman &>/dev/null; then
    print_log "This installer targets Arch Linux (pacman not found). Aborting."
    exit 1
fi

if ! command -v yay &>/dev/null; then
    print_log "yay (AUR helper) not found — installing it"
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/hykr-yay
    (cd /tmp/hykr-yay && makepkg -si --noconfirm)
    rm -rf /tmp/hykr-yay
fi

# --------------------------------------------------- // Packages
print_log "Installing core packages (Scripts/pkg_core.lst)"
mapfile -t core_pkgs < <(pkg_names "${scrDir}/pkg_core.lst")
yay -S --needed --noconfirm "${core_pkgs[@]}"

read -rp "Install optional apps too (vesktop, spotify, proton mail)? [y/N] " extra_choice
if [[ "${extra_choice,,}" == "y" ]]; then
    print_log "Installing optional packages (Scripts/pkg_extra.lst)"
    mapfile -t extra_pkgs < <(pkg_names "${scrDir}/pkg_extra.lst")
    yay -S --needed --noconfirm "${extra_pkgs[@]}"
fi

# --------------------------------------------------- // Dotfiles
print_log "Linking dotfiles (also seeds a default pywal theme if needed)"
"${scrDir}/link_dots.sh"

# --------------------------------------------------- // SDDM theme
read -rp "Install the pixel-sakura SDDM theme? [Y/n] " sddm_choice
if [[ "${sddm_choice,,}" != "n" ]]; then
    "${scrDir}/extra/install_sddm_theme.sh"
fi

# --------------------------------------------------- // Firewall
read -rp "Harden the firewall with firewalld? [Y/n] " fw_choice
if [[ "${fw_choice,,}" != "n" ]]; then
    "${scrDir}/extra/setup_firewall.sh"
fi

print_log "Install complete. Reboot to start SDDM / Hyprland."
