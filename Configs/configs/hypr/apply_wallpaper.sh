#!/bin/bash
# Applies a wallpaper (path given as $1) and propagates its pywal colors
# everywhere: awww, kitty, starship, swaync, pywalfox, the pywallpaper.jpg
# cache. Shared by every wallpaper picker in this repo (wallpaper.sh's own
# rofi/wofi menu, and the quickshell wallpaper-picker) so they all drive
# the exact same color pipeline instead of duplicating/diverging it.
set -e

selected_wallpaper="$1"
[ -z "$selected_wallpaper" ] && exit 0

awww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
wal -i "$selected_wallpaper" -n --cols16

if command -v swayosd-server &>/dev/null; then
    pkill swayosd-server || true
    swayosd-server &
fi

swaync-client --reload-css
cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf

# Recolor every already-open kitty window live too, not just ones
# opened after this switch -- kitty reads its config once at startup
# and never watches the file for changes on its own. Needs
# allow_remote_control in kitty.conf; each window auto-allocates its
# own socket and exports it via KITTY_LISTEN_ON in its environment, so
# read that straight out of /proc rather than guessing a shared path.
if command -v kitty &>/dev/null; then
    for pid in $(pgrep -x kitty); do
        sock=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^KITTY_LISTEN_ON=//p')
        [ -n "$sock" ] && kitty @ --to "$sock" set-colors --all -- ~/.cache/wal/colors-kitty.conf &>/dev/null || true
    done
fi

[ -f ~/.cache/wal/starship.toml ] && cat ~/.cache/wal/starship.toml > ~/.config/starship.toml

# hyprland.lua's require("colors-hyprland") reads from ~/.config/hypr, not
# ~/.cache -- require() only resolves modules under the config root.
[ -f ~/.cache/wal/colors-hyprland.lua ] && cat ~/.cache/wal/colors-hyprland.lua > ~/.config/hypr/colors-hyprland.lua

if [ -f ~/.cache/wal/spicetify-color.ini ]; then
    mkdir -p ~/.config/spicetify
    cat ~/.cache/wal/spicetify-color.ini > ~/.config/spicetify/color.ini
    if [ -f ~/.config/spicetify/config-xpui.ini ]; then
        sed -i -E "s/^color_scheme(\s*)=.*/color_scheme\1= HyKr/" ~/.config/spicetify/config-xpui.ini
        # Only reapply (which restarts/launches Spotify) if it's already
        # running -- picking a wallpaper shouldn't pop Spotify open.
        if pgrep -x spotify &>/dev/null && command -v spicetify &>/dev/null; then
            spicetify apply &>/dev/null
        fi
    fi
fi

command -v pywalfox &>/dev/null && pywalfox update

source ~/.cache/wal/colors.sh && cp "$selected_wallpaper" ~/wallpapers/pywallpaper.jpg
