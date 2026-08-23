# Keybinds

Every `bind`/`bindl`/`bindle`/`bindm`/`binde` line from
[`hyprland.conf`](hyprland.conf), grouped the same way the file itself
groups them, with the exact syntax so you can copy-paste straight into a
live `~/.config/hypr/hyprland.conf`. `$mod` = `SUPER`.

To update a live install: copy the block(s) you need into your live
`hyprland.conf`, then `hyprctl reload`.

## Terminal

```
bind = $mod, RETURN, exec, kitty
bind = $mod ALT, T, togglespecialworkspace, dropterm
```

`$mod ALT, T` opens a dropdown kitty on its own special workspace —
needs the matching `exec-once`/`windowrulev2` lines near the top of
`hyprland.conf`, not just the bind itself.

## Close, force-kill, exit

```
bind = $mod, Q, killactive,
bind = $mod ALT, F4, exec, kill -9 $(hyprctl activewindow -j | jq -r .pid)
bind = $mod, DELETE, exit,
bind = $mod, ESCAPE, exec, wlogout
bind = $mod, L, exec, hyprlock
```

Needs `jq` for the force-kill bind.

## Toggle

```
bind = $mod, T, togglefloating,
bind = $mod, G, togglegroup,
bind = $mod, J, togglesplit,
bind = $mod, M, exec, pkill -f 'quickshell -c hykr' || quickshell -c hykr
bind = $mod CTRL, B, exec, pkill waybar || waybar
bind = $mod, N, exec, swaync-client -t -sw
bind = $mod SHIFT, N, exec, pkill hyprsunset || hyprsunset
bind = $mod SHIFT, I, exec, pkill hypridle || hypridle
bind = $mod, S, exec, ~/.config/hypr/quick_settings.sh
```

`$mod, M` toggles the Quickshell quick-settings panel (see
[`../quickshell/hykr/shell.qml`](../quickshell/hykr/shell.qml)).
`$mod SHIFT, I` is "caffeine" — killing `hypridle` means no lock/dim/dpms
until you toggle it back on. `$mod, S` opens the wofi-based quick-settings
menu (see [`quick_settings.sh`](quick_settings.sh)) — a lighter
alternative to the Quickshell panel above.

## Launchers and apps

```
bind = $mod, TAB, exec, wofi --show drun -n
bind = $mod, E, exec, thunar
bind = $mod, C, exec, kate
bind = $mod, B, exec, brave
bind = $mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
```

Needs `cliphist` + `wl-clipboard` for the clipboard-history bind — see
the `wl-paste --watch cliphist store` lines in `hyprland.conf`'s
Autostart section.

## Workspace and theming

```
bind = $mod CTRL, right, workspace, r+1
bind = $mod CTRL, left, workspace, r-1
bind = $mod CTRL, down, workspace, empty
bind = $mod SHIFT, W, exec, ~/.config/hypr/wallpaper.sh
bind = $mod SHIFT, T, exec, ~/.config/hypr/theme.sh
```

`$mod SHIFT, W` is the wofi-based wallpaper picker (pywal + awww under
the hood — see [`wallpaper.sh`](wallpaper.sh)). `$mod SHIFT, T` is a
**stub**: no `theme.sh` exists in this repo yet, so this bind errors
until one is written.

## Alt

```
bind = ALT, P, pseudo,
bind = ALT, TAB, cyclenext,
bind = ALT SHIFT, TAB, cyclenext, prev
```

## Window movement

```
bind = $mod CTRL, H, changegroupactive, b
bind = $mod CTRL, L, changegroupactive, f
bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d
bind = $mod SHIFT, left, resizeactive, -30 0
bind = $mod SHIFT, right, resizeactive, 30 0
bind = $mod SHIFT, up, resizeactive, 0 -30
bind = $mod SHIFT, down, resizeactive, 0 30
bind = $mod CTRL SHIFT, left, movewindow, l
bind = $mod CTRL SHIFT, right, movewindow, r
bind = $mod CTRL SHIFT, up, movewindow, u
bind = $mod CTRL SHIFT, down, movewindow, d
bind = $mod SHIFT, comma, movewindow, mon:-1
bind = $mod SHIFT, period, movewindow, mon:+1
```

## Hold-to-move / hold-to-resize

Submap-based (press to enter, arrows to move/resize, Escape to exit) —
not a literal "hold," but close in spirit:

```
bind = $mod, Z, submap, move
submap = move
binde = , right, moveactive, 30 0
binde = , left, moveactive, -30 0
binde = , up, moveactive, 0 -30
binde = , down, moveactive, 0 30
bind = , escape, submap, reset
submap = reset

bind = $mod, X, submap, resize
submap = resize
binde = , right, resizeactive, 30 0
binde = , left, resizeactive, -30 0
binde = , up, resizeactive, 0 -30
binde = , down, resizeactive, 0 30
bind = , escape, submap, reset
submap = reset
```

## Workspaces: switch

```
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod, 6, workspace, 6
bind = $mod, 7, workspace, 7
bind = $mod, 8, workspace, 8
bind = $mod, 9, workspace, 9
bind = $mod, 0, workspace, 10
```

## Workspaces: move window to workspace

```
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bind = $mod SHIFT, 6, movetoworkspace, 6
bind = $mod SHIFT, 7, movetoworkspace, 7
bind = $mod SHIFT, 8, movetoworkspace, 8
bind = $mod SHIFT, 9, movetoworkspace, 9
bind = $mod SHIFT, 0, movetoworkspace, 10
```

## Workspaces: move window silently

```
bind = $mod ALT, 1, movetoworkspacesilent, 1
bind = $mod ALT, 2, movetoworkspacesilent, 2
bind = $mod ALT, 3, movetoworkspacesilent, 3
bind = $mod ALT, 4, movetoworkspacesilent, 4
bind = $mod ALT, 5, movetoworkspacesilent, 5
bind = $mod ALT, 6, movetoworkspacesilent, 6
bind = $mod ALT, 7, movetoworkspacesilent, 7
bind = $mod ALT, 8, movetoworkspacesilent, 8
bind = $mod ALT, 9, movetoworkspacesilent, 9
bind = $mod ALT, 0, movetoworkspacesilent, 10
```

## Screenshot

```
bind = , Print, exec, grim - | wl-copy
bind = $mod, P, exec, grim -g "$(slurp)" - | wl-copy
bind = $mod ALT, P, exec, grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name')" - | wl-copy
bind = $mod SHIFT, P, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png
```

Needs `grim`, `slurp`, `wl-clipboard`, and `jq` (for the focused-monitor
variant). `$mod SHIFT, P` saves to `~/Pictures/Screenshots` instead of
the clipboard — that directory is created at session start
(`hyprland.conf`'s Autostart section).

## Other (hardware, media, no modifier)

```
bind = SHIFT, F11, fullscreen, 0
bindl = , F10, exec, pamixer -t
bindle = , F11, exec, pamixer -d 5
bindle = , F12, exec, pamixer -i 5
```

Needs `pamixer`. `bindl`/`bindle` (not plain `bind`) so these still work
while the session is locked and repeat on hold.

## Mouse

```
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
```
