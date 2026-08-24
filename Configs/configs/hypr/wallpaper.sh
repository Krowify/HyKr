#!/bin/bash
# No longer bound to Super+Shift+W -- that's the quickshell wallpaper
# picker now (Configs/configs/quickshell/wallpaper-picker/). Left in
# place as a manual/fallback picker: a plain rofi/wofi dmenu list,
# useful if quickshell itself is ever unavailable.
#
# Wallpaper picker: rofi's icon grid if installed (reliable click-to-select),
# else wofi's plain text list as a fallback -> awww + pywal. Adapted from
# elifouts/Dotfiles (cava color sync removed — no cava config in this repo;
# pywalfox/swayosd calls guarded since they're optional, not in
# pkg_core.lst). wofi's own image-grid mode (allow_images + img: prefix) is
# deliberately not used here: its GtkFlowBox click-to-activate is flaky
# (same reason apply-theme.sh's dynamic-theme picker prefers rofi's grid
# and only falls back to a plain wofi list).
#
# The actual "apply this wallpaper" step (awww + pywal + kitty/starship/
# swaync/pywalfox propagation) lives in apply_wallpaper.sh, shared with
# the quickshell wallpaper-picker (Super+Shift+W) so both pickers drive
# the same color pipeline instead of duplicating it. That pipeline uses
# pywal's actual per-wallpaper colors rather than whatever theme-switcher
# theme is nominally active, same as fastfetch's ASCII art (colored
# through the terminal's own pywal-set ANSI palette) -- so picking a
# wallpaper always matches what you see in the terminal, even if it
# diverges from the last theme-switcher theme you applied.
WALLPAPER_DIR="$HOME/wallpapers"
ROFI_GRID_THEME="$HOME/.config/rofi/wallpaper-grid.rasi"

wallpapers() {
    find -L "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort
}

pick_with_rofi() {
    local input=""
    while IFS= read -r f; do
        input+="${f}\0icon\x1f${f}\n"
    done < <(wallpapers)

    local args=(-dmenu -p "Select Wallpaper")
    [ -f "$ROFI_GRID_THEME" ] && args+=(-theme "$ROFI_GRID_THEME")

    printf '%b' "$input" | rofi "${args[@]}"
}

pick_with_wofi() {
    wallpapers | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Select Wallpaper:" -n
}

main() {
    if command -v rofi &>/dev/null; then
        selected_wallpaper=$(pick_with_rofi)
    else
        selected_wallpaper=$(pick_with_wofi)
    fi
    [ -z "$selected_wallpaper" ] && exit 0

    "$(dirname "$(realpath "$0")")/apply_wallpaper.sh" "$selected_wallpaper"
}

main
