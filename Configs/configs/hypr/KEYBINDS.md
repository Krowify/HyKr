# Keybinds

Every bind in [`hyprland.lua`](hyprland.lua), grouped the same way the
file itself groups them. `Super` = `$mainMod`. For the exact copy-pasteable
syntax, see `hyprland.lua` directly — this page is the human-readable index.

## Terminal

| Keybind | Action |
| --- | --- |
| `Super+Return` | Terminal (Kitty) |
| `Super+Alt+T` | Dropdown terminal (own special workspace) |

## Close, force-kill, exit

| Keybind | Action |
| --- | --- |
| `Super+Q` | Close focused window |
| `Super+Alt+F4` | Force-kill focused window |
| `Super+Delete` | Exit Hyprland session |
| `Super+Escape` | Logout menu (Wlogout) |
| `Super+L` | Lock screen (Hyprlock) |

## Toggle

| Keybind | Action |
| --- | --- |
| `Super+T` | Toggle floating |
| `Super+G` | Toggle group |
| `Super+J` | Swap split (window positions — `togglesplit` is broken upstream in Hyprland 0.56.2, [hyprwm/Hyprland#15106](https://github.com/hyprwm/Hyprland/issues/15106)) |
| `Super+M` | Toggle quick-settings panel (Quickshell) |
| `Super+Ctrl+B` | Toggle the bar (Waybar, or the Laptop theme's Quickshell dock — whichever the active theme runs) |
| `Super+N` | Toggle notification center (the Laptop theme's Quickshell dock, else SwayNC) |
| `Super+Shift+N` | Toggle blue light filter (hyprsunset) |
| `Super+Shift+I` | Toggle caffeine (kills/restarts hypridle) |
| `Super+S` | Quick-settings menu (Wofi) |
| `Super+Shift+R` | Resync keybinds (reset stuck submap — fixes Super+J etc. going dead after hyprexpo) |

## Launchers and apps

| Keybind | Action |
| --- | --- |
| `Super+Tab` | App launcher (Wofi) |
| `Super+E` | File manager (Dolphin) |
| `Super+C` | Text editor (Kate) |
| `Super+B` | Web browser (Brave) |
| `Super+V` | Clipboard history (Cliphist + Wofi) |

## Workspace and theming

| Keybind | Action |
| --- | --- |
| `Super+Ctrl+Right`/`Left` | Next/previous workspace (relative) |
| `Super+Ctrl+Down` | Go to nearest empty workspace |
| `Super+Shift+W` | Wallpaper picker (Wofi + awww + pywal) |
| `Super+Shift+T` | Theme picker (Wofi) — switches Hyprland, Waybar, Wofi, Kitty, Fastfetch, Starship, Hyprlock, SwayNC, and Wlogout to one of the bundled themes |

## Alt

| Keybind | Action |
| --- | --- |
| `Alt+P` | Toggle pseudotile |
| `Alt+Tab` / `Alt+Shift+Tab` | Cycle windows forward/backward |

## Window movement

| Keybind | Action |
| --- | --- |
| `Super+Ctrl+H` / `Super+Ctrl+L` | Cycle window group backward/forward |
| `Super+Left/Right/Up/Down` | Focus window in direction |
| `Super+Shift+Left/Right/Up/Down` | Resize active window |
| `Super+Ctrl+Shift+Left/Right/Up/Down` | Move active window between tiles |
| `Super+Shift+,` / `Super+Shift+.` | Move window to previous/next monitor |
| `Super+Z` / `Super+X` | Move / resize window (arrow keys, Escape to exit) |

## Workspaces

| Keybind | Action |
| --- | --- |
| `Super+1` .. `Super+0` | Switch to workspace 1–10 |
| `Super+Shift+1` .. `Super+Shift+0` | Move window to workspace 1–10 |
| `Super+Alt+1` .. `Super+Alt+0` | Move window to workspace 1–10 (silent) |

## Screenshot

| Keybind | Action |
| --- | --- |
| `Print` | Screenshot all monitors to clipboard |
| `Super+P` | Screenshot region to clipboard |
| `Super+Alt+P` | Screenshot focused monitor to clipboard |
| `Super+Shift+P` | Screenshot region to file (`~/Pictures/Screenshots`) |

## Other (hardware, media, no modifier)

| Keybind | Action |
| --- | --- |
| `Shift+F11` | Toggle fullscreen |
| `F10` / `XF86AudioMute` | Mute volume |
| `F11` / `XF86AudioLowerVolume` | Lower volume |
| `F12` / `XF86AudioRaiseVolume` | Raise volume |

The `F10`-`F12` set is what the desktop keyboard sends; the `XF86Audio*` set
is what a laptop's dedicated volume keys send. Both are bound, so either
keyboard works from the same config.

## Mouse

| Keybind | Action |
| --- | --- |
| `Super+LeftClick` (drag) | Move window |
| `Super+RightClick` (drag) | Resize window |
