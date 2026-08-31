#!/usr/bin/env bash
# Main entrypoint: preflight -> (re-exec as non-root if needed) -> GPU
# drivers -> packages -> link dots -> enable services -> optional SDDM
# theme + firewall hardening. Run from anywhere: ~/HyKr/Scripts/install.sh

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

pkg_names() {
    grep -vE '^\s*#|^\s*$' "$1" | awk '{print $1}'
}

# Purple-to-blue gradient wordmark + subtitle, centered both horizontally
# and vertically in the terminal -- pure printf/ANSI truecolor, no
# dependency (unlike the gum prompts below, this needs to work even if
# gum's install fails).
print_logo() {
    local logo_path="${scrDir}/logo.txt"
    [[ -f "${logo_path}" ]] || return 0

    local term_width term_height
    term_width=$(tput cols 2>/dev/null || echo 80)
    term_height=$(tput lines 2>/dev/null || echo 24)

    local logo_width=0 line
    while IFS= read -r line; do
        (( ${#line} > logo_width )) && logo_width=${#line}
    done < "${logo_path}"

    local pad=$(( (term_width - logo_width) / 2 ))
    (( pad < 0 )) && pad=0
    local pad_str
    pad_str="$(printf '%*s' "${pad}" '')"

    local purple=(147 51 234) blue=(37 99 235)
    local total_lines
    total_lines=$(wc -l < "${logo_path}")

    # Vertical centering: logo rows + a blank line + the subtitle row +
    # a trailing blank line.
    local content_height=$(( total_lines + 2 ))
    local vpad=$(( (term_height - content_height) / 2 ))
    (( vpad < 0 )) && vpad=0

    clear
    for ((v = 0; v < vpad; v++)); do echo; done

    local i=0 t r g b
    while IFS= read -r line; do
        t=0
        (( total_lines > 1 )) && t=$(( i * 100 / (total_lines - 1) ))
        r=$(( purple[0] + (blue[0] - purple[0]) * t / 100 ))
        g=$(( purple[1] + (blue[1] - purple[1]) * t / 100 ))
        b=$(( purple[2] + (blue[2] - purple[2]) * t / 100 ))
        printf '%s\033[38;2;%d;%d;%dm%s\033[0m\n' "${pad_str}" "${r}" "${g}" "${b}" "${line}"
        (( i++ ))
    done < "${logo_path}"

    local subtitle="Hyprland by Krowify"
    local sub_pad=$(( (term_width - ${#subtitle}) / 2 ))
    (( sub_pad < 0 )) && sub_pad=0
    printf '\n%s\033[97m%s\033[0m\n' "$(printf '%*s' "${sub_pad}" '')" "${subtitle}"
}

# gum-backed confirm with a plain read fallback -- if gum's own install
# below fails for some reason, the rest of the installer's prompts
# shouldn't become unusable because of it.
confirm() {
    if command -v gum &>/dev/null; then
        gum confirm "$1"
    else
        local reply
        read -rp "$1 [Y/n] " reply
        [[ "${reply,,}" != "n" ]]
    fi
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

    TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
    if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
        print_log "Could not resolve a home directory for ${TARGET_USER}, aborting."
        exit 1
    fi

    # This repo was cloned as root (the normal state right after pacstrap,
    # before ${TARGET_USER} existed), so it lives under /root -- mode 0700,
    # unreadable by anyone but root. Re-execing via `su` below would fail
    # with "Permission denied" just trying to read install.sh, so move the
    # repo into the target user's home first.
    if [[ "${repoDir}" != "${TARGET_HOME}"/* ]]; then
        TARGET_REPO="${TARGET_HOME}/$(basename "${repoDir}")"
        if [[ -e "${TARGET_REPO}" ]]; then
            print_log "${TARGET_REPO} already exists — using it instead of moving ${repoDir}."
        else
            print_log "Moving ${repoDir} -> ${TARGET_REPO}"
            mv "${repoDir}" "${TARGET_REPO}"
        fi
        chown -R "${TARGET_USER}:" "${TARGET_REPO}"
        scrDir="${TARGET_REPO}/Scripts"

        if [[ ! -f "${scrDir}/global_fn.sh" ]]; then
            print_log "Moved the repo but ${scrDir}/global_fn.sh is missing — aborting before re-exec."
            ls -la "${TARGET_REPO}" "${scrDir}" 2>&1
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

print_logo

if ! command -v gum &>/dev/null; then
    sudo pacman -S --needed --noconfirm gum || print_log "gum install failed — prompts below will fall back to plain y/n"
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

print_log "Installing optional packages (Scripts/pkg_extra.lst)"
mapfile -t extra_pkgs < <(pkg_names "${scrDir}/pkg_extra.lst")
yay -S --needed --noconfirm "${extra_pkgs[@]}"

# --------------------------------------------------- // Dotfiles
print_log "Linking dotfiles (also seeds a default pywal theme if needed)"
"${scrDir}/link_dots.sh"

# --------------------------------------------------- // Default shell
# `id -un` instead of $USER -- the latter isn't guaranteed to be set
# depending on how this script got invoked (e.g. no pam_env in the chain).
CURRENT_USER="$(id -un)"
if [[ "$(getent passwd "${CURRENT_USER}" | cut -d: -f7)" != *zsh ]]; then
    print_log "Setting zsh as the default login shell for ${CURRENT_USER}"
    sudo chsh -s "$(command -v zsh)" "${CURRENT_USER}"
fi

# --------------------------------------------------- // Services
"${scrDir}/enable_services.sh"

# --------------------------------------------------- // SDDM theme
if confirm "Install the pixel-sakura SDDM theme?"; then
    "${scrDir}/extra/install_sddm_theme.sh"
fi

# --------------------------------------------------- // Firewall
if confirm "Harden the firewall with firewalld?"; then
    "${scrDir}/extra/setup_firewall.sh"
fi

# --------------------------------------------------- // Hyprland gesture plugins
if confirm "Install hyprexpo (Mission Control-style overview) + hyprgrass (touchpad gestures)?"; then
    "${scrDir}/extra/setup_hypr_gestures.sh"
fi

# --------------------------------------------------- // MAC randomization
if confirm "Randomize WiFi MAC address on every connection (privacy on untrusted/private networks)?"; then
    "${scrDir}/extra/setup_mac_randomization.sh"
fi

print_log "Install complete. Reboot to start SDDM / Hyprland."
