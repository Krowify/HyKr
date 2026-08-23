#!/usr/bin/env bash
# Main entrypoint: preflight -> (re-exec as non-root if needed) -> GPU
# drivers -> packages -> link dots -> enable services -> optional SDDM
# theme + firewall hardening. Run from anywhere: ~/HyKr/Scripts/install.sh

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

# --------------------------------------------------- // Root handoff
# link_dots.sh symlinks into $HOME, and yay's makepkg refuses to build AUR
# packages as root -- if this script is run as root (the normal state right
# after pacstrap, before you've made a user), the whole flow needs to run
# as a real non-root user instead. Re-exec under that user rather than
# trying to run only the AUR bits as them.
if [[ ${EUID} -eq 0 ]]; then
    read -rp "Username to run the install as (needs sudo access): " TARGET_USER

    if ! id "${TARGET_USER}" &>/dev/null; then
        echo "User '${TARGET_USER}' does not exist."
        read -rp "Create it now? [y/N] " CREATE_USER
        if [[ "${CREATE_USER,,}" == "y" ]]; then
            useradd -m -G wheel "${TARGET_USER}"
            echo "Set a password for ${TARGET_USER}:"
            passwd "${TARGET_USER}"
            if grep -q '^# %wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
                sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
                if ! visudo -c &>/dev/null; then
                    print_log "Enabling wheel-group sudo left /etc/sudoers invalid — reverting, aborting."
                    sed -i 's/^%wheel ALL=(ALL:ALL) ALL/# %wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
                    exit 1
                fi
            fi
        else
            print_log "A non-root user with sudo access is required. Exiting."
            exit 1
        fi
    fi

    # `su - user -c "..."` doesn't reliably keep a controlling terminal
    # attached, so any sudo call further down this script (pacman, yay,
    # systemctl, firewall-cmd, ...) could hang asking for a password that
    # has nowhere to be typed. Grant a temporary NOPASSWD for this one
    # install run rather than trying to enumerate every exact sudo command
    # this script and everything it calls might run (fragile -- unlike
    # arch-install's per-stage pinned grants, this script's later steps
    # call into other scripts with many varied sudo invocations). Scoped
    # to just this user, validated, and removed the moment this run ends.
    SUDOERS_DROPIN="/etc/sudoers.d/99-hykr-install"
    echo "${TARGET_USER} ALL=(ALL) NOPASSWD: ALL" > "${SUDOERS_DROPIN}"
    chmod 0440 "${SUDOERS_DROPIN}"
    if ! visudo -cf "${SUDOERS_DROPIN}"; then
        print_log "Generated sudoers drop-in failed validation, aborting."
        rm -f "${SUDOERS_DROPIN}"
        exit 1
    fi
    trap 'rm -f "${SUDOERS_DROPIN}"' EXIT

    print_log "Re-running install.sh as ${TARGET_USER}"
    su - "${TARGET_USER}" -c "bash '${scrDir}/install.sh'"

    rm -f "${SUDOERS_DROPIN}"
    trap - EXIT
    exit 0
fi

if ! command -v yay &>/dev/null; then
    print_log "yay (AUR helper) not found — installing it"
    sudo pacman -Syu --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/hykr-yay
    (cd /tmp/hykr-yay && makepkg -si --noconfirm)
    rm -rf /tmp/hykr-yay
fi

# --------------------------------------------------- // GPU drivers
"${scrDir}/install_gpu_drivers.sh"

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

# --------------------------------------------------- // Services
"${scrDir}/enable_services.sh"

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
