#!/bin/bash
# SDDM session wrapper (see hyprland-hykr.desktop) that runs BEFORE
# Hyprland's own launcher, /usr/bin/start-hyprland. Hyprland loads
# hyprland.lua INSTEAD of hyprland.conf whenever one exists, and that
# check happens once at the compositor's own binary startup -- before any
# exec-once directive in hyprland.conf can possibly run. Quarantining
# hyprmod's regenerated hyprland.lua from an exec-once (guard_lua_config.sh
# alone) is therefore always a session late: it only sets up the *next*
# login to use hyprland.conf again, not the one it runs in. Doing the
# quarantine here, before start-hyprland even runs, closes that gap.
"$HOME/.config/hypr/guard_lua_config.sh"
exec /usr/bin/start-hyprland "$@"
