# Blackturq

A true-black, turquoise-accented theme ported from
[HarmlessValve/HV-dotfiles](https://github.com/HarmlessValve/HV-dotfiles).

The palette is upstream's: `#0a0a0a` background, `#adf0e9` accent,
`#8fecd5` mint, `#d35f5f` red. `colors.json` is a straight transcription of
upstream's `hypr/colors.toml` plus the `@define-color` block in its
`waybar/style.css`, remapped onto HyKr's named colour roles.

## What it themes

| Surface | How |
| --- | --- |
| Window borders | Flat `#adf0e9` active border, via `templates/hyprland.lua.tpl` |
| Bar | The shared Quickshell dock, `quickshell -c laptop` (`"bar": "quickshell-dock"`) — a flat, top-anchored, full-width bar per screen |
| Notifications | That same Quickshell process, via its own native notification daemon — not swaync |
| Lock screen | `templates/hyprlock.conf.tpl` — flat black, no wallpaper |
| btop, cava | The shared `templates/btop.theme.tpl` and `templates/cava.config.tpl` |
| Wofi / rofi, kitty, starship, wlogout, fastfetch, GTK 3/4, Qt6, VS Code, Obsidian, spicetify, peaclock | The shared templates in `../../templates/`, same as every other theme |

Because the palette lives in `colors.json`, every one of those shared
templates renders in Blackturq with no per-theme file — which is why this
theme covers more surfaces than upstream HV-dotfiles does.

## Why it shares the Laptop dock

`quickshell -c laptop` is named after the theme that introduced it, but the
shell itself is generic: a top-anchored full-width bar per screen, whose
battery module hides itself when there is no battery
(`visible: Services.BatteryService.available`), so it is correct on a
desktop too. Its palette is not baked in — `apply-theme.sh` writes
`~/.config/quickshell/laptop/colors.json` from whichever theme is active,
and the shell's `FileView` repaints on write.

So Blackturq points at it rather than duplicating ~690 lines of QML for a
bar of the same shape. Switching between Blackturq and Laptop does not even
restart the process: `stop_other_qs_shells` keeps the one whose config
matches, and only the colours change.

## What was NOT ported, and why

Upstream picks different programs for four roles HyKr already fills. This
theme keeps HyKr's choices; the notes are here so the divergence is a
recorded decision rather than an oversight.

| Upstream | HyKr keeps | Why |
| --- | --- | --- |
| mako | the Quickshell dock's own notification daemon | Only one process can claim `org.freedesktop.Notifications`. Under `"bar": "quickshell-dock"`, `apply-theme.sh` stops both waybar and swaync and lets the dock serve notifications itself, so mako has nothing to replace. |
| walker | wofi + rofi | `apply-theme.sh` resolves its launcher by name (`_PICKER`) and ships `.rasi` templates. Walker uses its own XML layout format (14 `item_*.xml` files), so supporting it is a feature, not a theme. |
| waybar | the Quickshell dock | This theme originally shipped its own flat waybar layout. It now runs the Quickshell dock instead, alongside Laptop and Hyperspace; the waybar templates were removed rather than left inert. `git show 9e0b789` still has them if the flat waybar bar is ever wanted back. |
| ghostty | kitty | Harmless to install both, but kitty is hardcoded in swaync's quick actions and wofi. Upstream's two GLSL cursor shaders are ghostty-only and have no equivalent here. |
| `kdeglobals` + `color-schemes/*.colors` | qt6ct | Two competing mechanisms for the same Qt apps. HyKr sets `QT_QPA_PLATFORMTHEME=qt6ct` and generates `qt6ct-colors.conf`, so a dropped-in `kdeglobals` would be inert at best. |

Three smaller divergences:

- **Border gradient.** Upstream's `col.active_border` is an 8-stop
  gradient. `apply-theme.sh` renders `{{border_active}}` as a single
  `rgba()` because Hyprland's Lua config validates that field as one
  colour, not as hyprlang's gradient string. The flat turquoise is
  deliberate — see the comment at the top of `templates/hyprland.lua.tpl`.
- **Warm colours.** Upstream's palette has no yellow or orange; it folds
  those ANSI slots into cool tones. HyKr's shared templates need them
  (battery warnings, git status, diff highlights), so `colors.json` extends
  the ramp from upstream's one warm colour, `#d35f5f`, into `#d3895f` and
  `#d3b75f`.

- **Inactive window border.** Upstream uses `rgb(272b30)`. `apply-theme.sh`
  hardcodes the inactive border to the theme's background for every theme
  (`border_inactive="$bg"`), so Hyprland gets `#0a0a0a` here. The
  `border_inactive` key in `colors.json` is still honoured — it feeds the
  GTK 3 colour sheet — it just isn't what Hyprland reads.

## Shadows

`theme.json` has no field for shadow range or render power, so this theme
gets `apply-theme.sh`'s global values rather than upstream's
`range = 20, render_power = 6`. Nothing is broken by that; it is just the
one part of upstream's `look_and_feel.lua` the current theme schema cannot
express.
