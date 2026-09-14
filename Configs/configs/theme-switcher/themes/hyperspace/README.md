# Hyperspace

A dusk-blue, wallpaper-driven theme built around
`Source/wallpapers/anime/a_person_in_the_air_above_a_city.png`.

Everything visible is derived from whichever wallpaper the theme is applied
with -- `"dynamic_colors": true` sends it through matugen on every apply,
and the generated palette lands in `colors.json`, which every surface below
renders from. The `colors.json` committed here is only a seed for a fresh
install (and for the theme picker's preview); on a live machine it is
whatever the last apply generated.

## What it themes

| Surface | How |
| --- | --- |
| Window borders | Accent + accent_alt as a 45° gradient on the active border, via `~/.config/hypr/colors-hyprland.lua` (see `templates/hyprland.lua.tpl`) |
| Bar / notifications | Its own Quickshell shell, `quickshell -c hyperspace` (`"bar": "quickshell-dock"`) — see `Configs/configs/quickshell/hyperspace/` |
| Wofi / rofi | The shared `templates/wofi.css.tpl` and `templates/rofi/*.tpl`, re-rendered on both a theme switch and a plain wallpaper pick |
| Lock screen | `templates/hyprlock.conf.tpl` — shows the theme's own wallpaper, blurred |
| fastfetch | `assets/fastfetch-logo.png` instead of the random-Pokémon logo, plus the usual accent→fg key gradient |
| kitty, starship, swaync, wlogout, GTK 3/4, Qt6, VS Code, Obsidian, spicetify | The shared templates in `../../templates/`, same as every other theme |

## The dock

Hyperspace does not run waybar. `theme.json`'s `"bar": "quickshell-dock"`
plus `"quickshell": { "config": "hyperspace" }` tells `apply-theme.sh` (and
`hypr/start_bar.sh`, and `hypr/dock_ipc.sh`) to run
`quickshell -c hyperspace` instead of the waybar+swaync pair. That shell
carries the bar, the notification daemon and the popup panels — full
details in `Configs/configs/quickshell/hyperspace/README.md`.

## Switching to it

```shell
~/.config/theme-switcher/apply-theme.sh hyperspace                 # pick a wallpaper
~/.config/theme-switcher/apply-theme.sh hyperspace <path-to-image> # or name one
```

or `Super+Shift+T` and choose Hyperspace.
