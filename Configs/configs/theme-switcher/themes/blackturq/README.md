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
| Bar | Its own flat full-width waybar (`templates/waybar/`), not a centre island |
| Notifications | swaync, via the shared `templates/swaync/*` |
| Lock screen | `templates/hyprlock.conf.tpl` — flat black, no wallpaper |
| btop, cava | The shared `templates/btop.theme.tpl` and `templates/cava.config.tpl` |
| Wofi / rofi, kitty, starship, wlogout, fastfetch, GTK 3/4, Qt6, VS Code, Obsidian, spicetify, peaclock | The shared templates in `../../templates/`, same as every other theme |

Because the palette lives in `colors.json`, every one of those shared
templates renders in Blackturq with no per-theme file — which is why this
theme covers more surfaces than upstream HV-dotfiles does.

## What was NOT ported, and why

Upstream picks different programs for four roles HyKr already fills. This
theme keeps HyKr's choices; the notes are here so the divergence is a
recorded decision rather than an oversight.

| Upstream | HyKr keeps | Why |
| --- | --- | --- |
| mako | swaync | Hard conflict: both claim `org.freedesktop.Notifications`, so only one can run. swaync is also load-bearing here — `apply-theme.sh`'s bar-mode block starts and stops it, and it has its own shared templates. Upstream's mako colours are reproduced through those. |
| walker | wofi + rofi | `apply-theme.sh` resolves its launcher by name (`_PICKER`) and ships `.rasi` templates. Walker uses its own XML layout format (14 `item_*.xml` files), so supporting it is a feature, not a theme. |
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
