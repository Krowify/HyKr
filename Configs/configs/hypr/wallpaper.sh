#!/bin/bash
# Wallpaper picker: rofi's icon grid if installed (reliable click-to-select),
# else wofi's plain text list as a fallback -> awww + pywal. Adapted from
# elifouts/Dotfiles (cava color sync removed — no cava config in this repo;
# pywalfox/swayosd calls guarded since they're optional, not in
# pkg_core.lst). wofi's own image-grid mode (allow_images + img: prefix) is
# deliberately not used here: its GtkFlowBox click-to-activate is flaky
# (same reason apply-theme.sh's dynamic-theme picker prefers rofi's grid
# and only falls back to a plain wofi list).
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

    awww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
    wal -i "$selected_wallpaper" -n --cols16

    if command -v swayosd-server &>/dev/null; then
        pkill swayosd-server
        swayosd-server &
    fi

    swaync-client --reload-css
    cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf

    command -v pywalfox &>/dev/null && pywalfox update

    source ~/.cache/wal/colors.sh && cp "$wallpaper" ~/wallpapers/pywallpaper.jpg
}

main
