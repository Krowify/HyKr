#!/bin/bash
# NOTE: this picker and theme-switcher/apply-theme.sh both own
# ~/.config/waybar/{config,style.css}. This one writes them from
# waybar/themes/<name>/; apply-theme.sh regenerates them from the ACTIVE
# theme's templates/waybar/ on every theme switch. So a layout picked here
# survives until the next Super+Shift+T, then gets replaced -- which reads
# as "my waybar layout keeps resetting itself" if you don't know both exist.
# Pick a layout here for a quick look; to make one stick, copy it into the
# theme's own templates/waybar/ under theme-switcher/themes/<theme>/.
WAYBAR_DIR="$HOME/.config/waybar"
STYLECSS="$WAYBAR_DIR/style.css"
CONFIG="$WAYBAR_DIR/config"
ASSETS="$WAYBAR_DIR/assets"
THEMES="$WAYBAR_DIR/themes"
menu() {
    find "${ASSETS}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}
main() {
    choice=$(menu | wofi -c ~/.config/wofi/waybar -s ~/.config/wofi/style-waybar.css --show dmenu --prompt "  Select Waybar (Scroll with Arrows)" -n)
    selected_wallpaper=$(echo "$choice" | sed 's/^img://')
    echo $selected_wallpaper
    if [[ "$selected_wallpaper" == "$ASSETS/experimental.png" ]]; then
        cat $THEMES/experimental/style-experimental.css > $STYLECSS
        cat $THEMES/experimental/config-experimental > $CONFIG
        pkill waybar && waybar
    elif [[ "$selected_wallpaper" == "$ASSETS/main.png" ]]; then
        cat $THEMES/default/style-default.css > $STYLECSS
        cat $THEMES/default/config-default > $CONFIG
        pkill waybar && waybar
    elif [[ "$selected_wallpaper" == "$ASSETS/line.png" ]]; then
        cat $THEMES/line/style-line.css > $STYLECSS
        cat $THEMES/line/config-line > $CONFIG
        pkill waybar && waybar
    elif [[ "$selected_wallpaper" == "$ASSETS/zen.png" ]]; then
        cat $THEMES/zen/style-zen.css > $STYLECSS
        cat $THEMES/zen/config-zen > $CONFIG
        pkill waybar && waybar
    fi

}
main
