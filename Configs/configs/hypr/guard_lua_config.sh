#!/bin/bash
# hyprmod can (re)generate ~/.config/hypr/hyprland.lua, and Hyprland loads
# a .lua config INSTEAD of hyprland.conf whenever one exists -- silently
# orphaning every hyprland.conf edit (this bit us for a whole debugging
# session: env vars, windowrules, generated-theme.conf sourcing, none of
# it took effect while hyprland.lua existed). Quarantine any hyprmod-lua
# files on every session start so the next login always uses
# hyprland.conf again.
HYPR_DIR="$HOME/.config/hypr"
QUARANTINE="$HYPR_DIR/lua-disabled"

shopt -s nullglob
lua_files=("$HYPR_DIR"/hyprland*.lua)
shopt -u nullglob

[ ${#lua_files[@]} -eq 0 ] && exit 0

mkdir -p "$QUARANTINE"
mv -f "${lua_files[@]}" "$QUARANTINE/"
notify-send "HyKr" "hyprmod's hyprland.lua was quarantined to lua-disabled/ so hyprland.conf stays in control -- reload/relogin to use its latest changes" 2>/dev/null || true
