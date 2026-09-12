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

# Sourced early (moved up from the end of this script) so every step
# below -- rofi included -- has $background/$foreground/$colorN as
# plain bash variables to render with, not just files under ~/.cache.
source ~/.cache/wal/colors.sh

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

# Rofi (wallpaper-grid.rasi / theme-picker.rasi): apply-theme.sh already
# renders these two from theme.json's static colors on a theme switch,
# but nothing re-rendered them on a plain wallpaper pick within the same
# theme -- same "last write wins" pattern as kitty/starship above, just
# re-run with wal's colors instead of theme.json's. accent/surface/
# surface2/fg_dim map onto the same color4/color8/color0/color7 slots
# starship's own pywal template already uses for the same roles.
ROFI_TPL_DIR="$HOME/.config/theme-switcher/templates/rofi"
ROFI_OUT_DIR="$HOME/.config/rofi"

if [ -d "$ROFI_TPL_DIR" ]; then
    mkdir -p "$ROFI_OUT_DIR"

    for tpl in "$ROFI_TPL_DIR"/*.tpl; do
        [ -f "$tpl" ] || continue
        out="$ROFI_OUT_DIR/$(basename "$tpl" .tpl)"

        sed \
            -e "s/{{bg}}/$background/g" \
            -e "s/{{fg}}/$foreground/g" \
            -e "s/{{fg_dim}}/$color7/g" \
            -e "s/{{surface}}/$color8/g" \
            -e "s/{{surface2}}/$color0/g" \
            -e "s/{{accent}}/$color4/g" \
            -e "s/{{font_family}}/JetBrainsMono Nerd Font/g" \
            "$tpl" > "$out"
    done
fi

# Wofi (Super+Tab launcher): same gap as rofi above -- apply-theme.sh
# only ever renders wofi's style.css on a theme switch. hex_to_rgba_css
# mirrors apply-theme.sh's own helper of the same name (bg 0.85, surface
# 0.70, accent-soft 0.15 alphas, matching what it uses for the same
# roles there).
hex_to_rgba_css() {
    local hex="${1#\#}" alpha="${2:-1}"
    printf "rgba(%d,%d,%d,%s)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}" "$alpha"
}

WOFI_TPL="$HOME/.config/theme-switcher/templates/wofi.css.tpl"
WOFI_OUT="$HOME/.config/wofi/style.css"

if [ -f "$WOFI_TPL" ]; then
    mkdir -p "$HOME/.config/wofi"

    sed \
        -e "s/{{bg_rgba}}/$(hex_to_rgba_css "$background" "0.85")/g" \
        -e "s/{{surface_rgba}}/$(hex_to_rgba_css "$color8" "0.70")/g" \
        -e "s/{{fg}}/$foreground/g" \
        -e "s/{{accent}}/$color4/g" \
        -e "s/{{accent_soft}}/$(hex_to_rgba_css "$color4" "0.15")/g" \
        -e "s/{{bg}}/$background/g" \
        -e "s/{{font_family}}/JetBrainsMono Nerd Font/g" \
        -e "s/{{font_family_bold}}/JetBrainsMono Nerd Font Bold/g" \
        "$WOFI_TPL" > "$WOFI_OUT"
fi

# Quickshell laptop dock accent (the active-workspace pill). $color4 is the
# same pywal slot the Hyprland border, rofi and wofi accents above already
# use, so the dock matches them rather than drifting on its own. The dock's
# FileView watches this file, so it repaints immediately -- the equivalent of
# the live kitty recolour a few lines up.
#
# Skipped while ~/.config/quickshell is still a symlink into the repo (a
# fresh install where no theme has been applied and the picker has never
# run): writing through it would modify a tracked file. apply-theme.sh
# de-symlinks it and writes the same value on the next theme apply.
QS_DOCK_COLORS="$HOME/.config/quickshell/laptop/colors.json"

if [ ! -L "$HOME/.config/quickshell" ] && [ -d "$(dirname "$QS_DOCK_COLORS")" ]; then
    printf '{\n    "accent": "%s"\n}\n' "$color4" > "$QS_DOCK_COLORS"
fi

# hyprland.lua's require("colors-hyprland") reads from ~/.config/hypr, not
# ~/.cache -- require() only resolves modules under the config root.
[ -f ~/.cache/wal/colors-hyprland.lua ] && cat ~/.cache/wal/colors-hyprland.lua > ~/.config/hypr/colors-hyprland.lua

# ...and tell the running Hyprland about it. Writing the file alone changes
# nothing live: hyprland.lua does require("colors-hyprland") once, at config
# parse time, so the border keeps whatever colour it had at the last reload.
# apply-theme.sh gets away without this because it ends in `hyprctl reload`;
# a wallpaper pick never reloaded anything, which is why the active-window
# border stayed on the previous wallpaper's accent while kitty, starship,
# rofi and wofi all moved.
#
# `hyprctl keyword` rather than `hyprctl reload`: it takes effect instantly
# and avoids re-parsing the whole config, which would also re-pin every
# monitor (see hyprland.lua's note on why the monitor block is explicit).
# The file write above is what makes it survive the next reload or relog.
#
# 0xff-prefixed, matching wal/templates/colors-hyprland.lua's own format.
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl keyword general:col.active_border "0xff${color4#\#}" >/dev/null 2>&1 || true
    hyprctl keyword general:col.inactive_border "0xff${background#\#}" >/dev/null 2>&1 || true
fi

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

cp "$selected_wallpaper" ~/wallpapers/pywallpaper.jpg
