#!/bin/bash
# Wallpaper picker: wofi -> awww + pywal. Adapted from elifouts/Dotfiles
# (cava color sync removed — no cava config in this repo; pywalfox/swayosd
# calls guarded since they're optional, not in pkg_core.lst).
WALLPAPER_DIR="$HOME/wallpapers"

menu() {
    find -L "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}

main() {
    choice=$(menu | wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Select Wallpaper:" -n)
    selected_wallpaper=$(echo "$choice" | sed 's/^img://')
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
