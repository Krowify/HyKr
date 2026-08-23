#!/usr/bin/env bash
# Auto-detects the GPU via lspci and installs matching drivers, no prompt.
# mesa covers AMD/Intel with nothing else needed; Nvidia needs its own
# proprietary driver on top. Detection logic and package choices match
# Krowify/arch-install's stage 1, made non-interactive.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

if ! command -v lspci &>/dev/null; then
    print_log "lspci not found — installing pciutils to detect the GPU"
    sudo pacman -S --needed --noconfirm pciutils
fi

print_log "Installing mesa (AMD/Intel + base Vulkan/OpenGL — needed regardless of GPU)"
sudo pacman -S --needed --noconfirm mesa

GPU_VENDOR=""
if lspci | grep -qi nvidia; then
    GPU_VENDOR="nvidia"
elif lspci | grep -qiE 'intel.*(vga|graphics|display)'; then
    GPU_VENDOR="intel"
elif lspci | grep -qiE '(vga|display).*amd|amd.*(vga|display)|advanced micro devices.*display'; then
    GPU_VENDOR="amd"
fi

case "${GPU_VENDOR}" in
    nvidia)
        print_log "Nvidia GPU detected — installing nvidia-open (Turing/2018+ cards)"
        sudo pacman -S --needed --noconfirm nvidia-open nvidia-utils egl-wayland
        print_log "NOTE: if your card predates Turing (pre-GTX 16xx/RTX 20xx) and Hyprland"
        print_log "fails to start, swap it: sudo pacman -S nvidia nvidia-utils egl-wayland"
        print_log "NOTE: Nvidia also needs 'nvidia_drm.modeset=1' on the kernel command line"
        print_log "(GRUB/systemd-boot/etc.) — this repo doesn't manage the bootloader, so add"
        print_log "it yourself, then reboot, or Hyprland likely won't start."
        ;;
    intel|amd)
        print_log "${GPU_VENDOR} GPU detected — mesa is all it needs, nothing further to install"
        ;;
    *)
        print_log "WARNING: couldn't identify the GPU vendor from lspci output. mesa is"
        print_log "installed (covers AMD/Intel), but if you're on Nvidia you'll need to"
        print_log "install its driver yourself: sudo pacman -S nvidia-open nvidia-utils egl-wayland"
        ;;
esac
