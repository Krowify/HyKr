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
| `Super+J` | Toggle split |
| `Super+M` | Toggle quick-settings panel (Quickshell) |
| `Super+Ctrl+B` | Toggle Waybar |
| `Super+N` | Toggle notification center (SwayNC) |
| `Super+Shift+N` | Toggle blue light filter (hyprsunset) |
| `Super+Shift+I` | Toggle caffeine (kills/restarts hypridle) |
| `Super+S` | Quick-settings menu (Wofi) |

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
| `F10` | Mute volume |
| `F11` | Lower volume |
| `F12` | Raise volume |

## Mouse

| Keybind | Action |
| --- | --- |
| `Super+LeftClick` (drag) | Move window |
| `Super+RightClick` (drag) | Resize window |
