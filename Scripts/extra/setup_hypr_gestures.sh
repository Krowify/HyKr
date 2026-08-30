#!/usr/bin/env bash
# One-time hyprpm setup for the touchpad gesture stack: hyprexpo (Mission
# Control-style workspace overview) and hyprgrass (touchpad swipe/pinch/tap
# bindings). Both are runtime hyprpm plugins, not pacman packages, so they
# can't live in pkg_core.lst/pkg_extra.lst -- hyprpm clones, builds, and
# loads them itself.
#
# hyprexpo comes from sandwichfarm/hyprexpo, not hyprwm/hyprland-plugins --
# the original hyprexpo was retired from that official repo
# (github.com/hyprwm/hyprland-plugins/pull/663); this fork is the actively
# maintained continuation.

scrDir="$(dirname "$(dirname "$(realpath "$0")")")"
source "${scrDir}/global_fn.sh" || {
    echo "Error: unable to source ${scrDir}/global_fn.sh"
    ls -la "${scrDir}/global_fn.sh" 2>&1
    exit 1
}

if ! command -v hyprpm &>/dev/null; then
    print_log "hyprpm not found (ships with the hyprland package) — install hyprland first."
    exit 1
fi

print_log "Updating hyprpm's plugin header cache to match this Hyprland build"
hyprpm update

# `hyprpm add` errors on a repo that's already added -- harmless, and lets
# this script be re-run safely (matches the rest of this repo's install
# scripts being idempotent).
print_log "Adding hyprexpo (Mission Control-style overview) from sandwichfarm/hyprexpo"
hyprpm add https://github.com/sandwichfarm/hyprexpo || true
hyprpm enable hyprexpo

print_log "Adding hyprgrass (touchpad swipe/pinch/tap bindings) from horriblename/hyprgrass"
hyprpm add https://github.com/horriblename/hyprgrass || true
hyprpm enable hyprgrass

print_log "Reloading hyprpm plugins"
hyprpm reload

print_log "Done. hyprland.lua already has the gesture/hyprexpo config -- run 'hyprctl reload' (or relog) to pick it up."
