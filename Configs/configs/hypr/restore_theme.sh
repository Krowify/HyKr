#!/usr/bin/env bash
# Put back at login what the theme switcher last set. Runs from hyprland.lua's
# autostart, before start_bar.sh.
#
# Two things were never restored on relog:
#
#   1. The wallpaper. The autostart started awww-daemon and stopped there --
#      nothing ever ran `awww img`, so whether your wallpaper came back was
#      entirely down to the daemon restoring its own cache. When it didn't you
#      logged in to a blank background, which reads as "the theme reverted"
#      even when every other surface is correct.
#
#   2. A generated file that has gone missing. hyprland.lua pcall-requires
#      generated-theme.lua and colors-hyprland.lua and now survives their
#      absence -- but it survives by falling back to Hyprland's own defaults,
#      i.e. a desktop with none of your theme's gaps, rounding, blur or border
#      colours. Re-render rather than leaving it like that.
#
# The theme itself is not re-applied when it doesn't need to be: apply-theme.sh
# tears down and restarts bars, re-runs matugen for dynamic themes and
# re-renders a dozen templates. That is the repair path, not the happy path.
#
# Always exits 0 -- a login must not fail because a wallpaper is missing.
set -uo pipefail

BASE="$HOME/.config/theme-switcher"
CURRENT="$BASE/current-theme.json"

log() { echo "restore_theme.sh: $*" >&2; }

command -v jq >/dev/null 2>&1 || { log "jq not installed -- nothing to do"; exit 0; }
[[ -r "$CURRENT" ]] || { log "no ${CURRENT} -- no theme recorded, nothing to restore"; exit 0; }

theme="$(jq -r '.theme // empty' "$CURRENT" 2>/dev/null || true)"
[[ -n "$theme" ]] || { log "${CURRENT} names no theme"; exit 0; }

THEME_PATH="$BASE/themes/$theme"
[[ -d "$THEME_PATH" ]] || { log "recorded theme '${theme}' has no directory at ${THEME_PATH}"; exit 0; }

# --------------------------------------------------- // Which wallpaper
# Same resolution order apply-theme.sh uses, so the two cannot disagree:
# the theme's own current-wallpaper.txt (absolute, written when a wallpaper is
# picked for a dynamic theme), then what current-theme.json recorded, then the
# theme's default_wallpaper. Relative paths resolve inside the theme directory.
wp=""
if [[ -r "$THEME_PATH/current-wallpaper.txt" ]]; then
    wp="$(cat "$THEME_PATH/current-wallpaper.txt" 2>/dev/null || true)"
fi
[[ -n "$wp" ]] || wp="$(jq -r '.wallpaper // empty' "$CURRENT" 2>/dev/null || true)"
[[ -n "$wp" ]] || wp="$(jq -r '.default_wallpaper // empty' "$THEME_PATH/theme.json" 2>/dev/null || true)"
[[ -n "$wp" && "$wp" != /* ]] && wp="$THEME_PATH/$wp"

# --------------------------------------------------- // Repair a broken theme
# Only generated-theme.lua is checked: it is the one whose absence visibly
# strips the desktop back to Hyprland's defaults. colors-hyprland.lua alone
# just means default border colours, and apply-theme.sh rewrites both anyway.
if [[ ! -f "$HOME/.config/hypr/generated-theme.lua" ]]; then
    log "generated-theme.lua is missing -- re-applying '${theme}' to rebuild it"
    if [[ -x "$BASE/apply-theme.sh" ]]; then
        # The wallpaper argument matters: a dynamic_colors theme invoked with no
        # second argument opens a rofi/wofi wallpaper PICKER, which at login
        # would sit there waiting for a choice nobody is there to make.
        if [[ -n "$wp" && -f "$wp" ]]; then
            if "$BASE/apply-theme.sh" "$theme" "$wp" >/dev/null 2>&1; then
                log "re-applied '${theme}'"
            else
                log "apply-theme.sh '${theme}' failed -- desktop stays on Hyprland defaults"
            fi
        elif [[ "$(jq -r '.dynamic_colors // false' "$THEME_PATH/theme.json" 2>/dev/null)" == "true" ]]; then
            # Bailing out is the right call: invoked without a wallpaper, a
            # dynamic_colors theme opens a rofi/wofi picker, which at login
            # means a menu sitting on screen waiting for nobody.
            log "'${theme}' is a dynamic theme and no wallpaper resolved -- NOT re-applying"
            log "  (it would open a wallpaper picker). Fix by hand: ~/.config/theme-switcher/apply-theme.sh ${theme}"
        elif "$BASE/apply-theme.sh" "$theme" >/dev/null 2>&1; then
            log "re-applied '${theme}'"
        else
            log "apply-theme.sh '${theme}' failed -- desktop stays on Hyprland defaults"
        fi
        # apply-theme.sh sets the wallpaper and starts this theme's bar itself,
        # so there is nothing left for the wallpaper block below to do.
        exit 0
    fi
    log "apply-theme.sh not executable at ${BASE} -- cannot repair"
fi

# --------------------------------------------------- // Wallpaper
[[ -n "$wp" ]] || { log "no wallpaper recorded for '${theme}'"; exit 0; }
[[ -f "$wp" ]] || { log "recorded wallpaper is gone: ${wp}"; exit 0; }
command -v awww >/dev/null 2>&1 || { log "awww not installed"; exit 0; }

# hyprland.lua starts awww-daemon in the same autostart batch, so it may not be
# listening yet. Same wait apply-theme.sh's ensure_swww() uses, just longer --
# at login there is more competing for the CPU than during a theme switch.
if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
fi
ready=false
for _ in {1..60}; do
    if awww query >/dev/null 2>&1; then ready=true; break; fi
    sleep 0.1
done
$ready || { log "awww-daemon never became ready -- wallpaper not restored"; exit 0; }

# No transition: this is a restore at login, not a change the user is watching.
awww img "$wp" --transition-type none >/dev/null 2>&1 ||
    log "awww could not set ${wp}"

exit 0
