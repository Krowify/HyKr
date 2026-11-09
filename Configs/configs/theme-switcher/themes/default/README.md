# Default

A near-black, mustard-accented theme. It started as a port of
[HarmlessValve/HV-dotfiles](https://github.com/HarmlessValve/HV-dotfiles),
whose turquoise palette is called Blackturq -- which is also what this theme
was called here until it was renamed to Default (`apply-theme.sh blackturq`
still works and means this theme).

The palette is now matched to the theme's default wallpaper
(`wallpapers/guitar_case.jpg`) rather than upstream's: `#0d0b0b`
background, the smiley's mustard `#dcae6e` as the accent and active
border, the plant pot's terracotta `#d16b64` as the second accent, and warm
greys and the shutter's maroon `#6f4c50` for the neutrals. Upstream's
turquoise (`#adf0e9` accent, `#8fecd5` mint) went with the old
`blackturq.jpg`, which is still in `wallpapers/` to pick.

## What it themes

| Surface | How |
| --- | --- |
| Window borders | Flat mustard `#dcae6e` active border, via `templates/hyprland.lua.tpl` |
| Bar | The shared Quickshell dock, `quickshell -c laptop`, in its `"layout": "islands"` form: three islands floating 8px in from the top and sides — workspaces on the left, the clock in the centre, battery/volume/network/bluetooth/date/notifications on the right. The two side islands are always the same width, and the left one adds CPU and RAM utilisation whenever both side islands still clear the centre one at that width (per screen — a narrow monitor just leaves them out). 15px corners, a warm grey `#a89383` outline, a 14px clock and date in your kitty font (`"font": "kitty"` — read from kitty.conf's `font_family` on each theme apply; icons stay on JetBrainsMono Nerd Font), colours from this theme's palette. All set in `theme.json`'s `"quickshell"` block (see `quickshell/laptop/Colors.qml`); Sakura runs the same shell as one flat edge-to-edge bar |
| Notifications | That same Quickshell process, via its own native notification daemon |
| Lock screen | `templates/hyprlock.conf.tpl` — flat black, no wallpaper |
| fastfetch | `assets/hykr-logo.txt` — a "HyKr" wordmark instead of the random-Pokémon logo, centred against the info column (`padding_top: 4`) and shaded row by row with the same accent→text gradient as the info keys (`$1`–`$8`; `$9` is the dim `hyprland · arch` tag), filled from the palette on every apply |
| btop, cava | The shared `templates/btop.theme.tpl` and `templates/cava.config.tpl` |
| Wofi / rofi, kitty, starship, wlogout, GTK 3/4, Qt6, VS Code, Obsidian, spicetify | The shared templates in `../../templates/`, same as every other theme |

Because the palette lives in `colors.json`, every one of those shared
templates renders in Default with no per-theme file — which is why this
theme covers more surfaces than upstream HV-dotfiles does.

## Why it shares Sakura's dock

`quickshell -c laptop` is named after the theme that introduced it (Sakura,
which was called Laptop then), but the shell itself is generic: a top-anchored full-width bar per screen, whose
battery module hides itself when there is no battery
(`visible: Services.BatteryService.available`), so it is correct on a
desktop too. Its palette is not baked in — `apply-theme.sh` writes
`~/.config/quickshell/laptop/colors.json` from whichever theme is active,
and the shell's `FileView` repaints on write.

So Default points at it rather than duplicating ~690 lines of QML for a
bar of the same shape, and draws it differently through its `theme.json`'s
`"quickshell"` block (floating, rounded, lighter outline, larger clock and
date -- see `quickshell/laptop/Colors.qml`), where Sakura keeps the flat
edge-to-edge strip.

## What was NOT ported, and why

Upstream picks different programs for four roles HyKr already fills. This
theme keeps HyKr's choices; the notes are here so the divergence is a
recorded decision rather than an oversight.

| Upstream | HyKr keeps | Why |
| --- | --- | --- |
| mako | the Quickshell dock's own notification daemon | Only one process can claim `org.freedesktop.Notifications`. The Quickshell dock serves notifications itself, so mako has nothing to replace. |
| walker | wofi + rofi | `apply-theme.sh` resolves its launcher by name (`_PICKER`) and ships `.rasi` templates. Walker uses its own XML layout format (14 `item_*.xml` files), so supporting it is a feature, not a theme. |
| waybar | the Quickshell dock | This theme originally shipped its own flat waybar layout. It now runs the Quickshell dock instead, alongside Sakura and Hyperspace; the waybar templates were removed rather than left inert. `git show 9e0b789` still has them if the flat waybar bar is ever wanted back. |
| ghostty | kitty | Harmless to install both, but kitty is HyKr's hardcoded terminal (`hyprland.lua`, wofi). Upstream's two GLSL cursor shaders are ghostty-only and have no equivalent here. |
| `kdeglobals` + `color-schemes/*.colors` | qt6ct | Two competing mechanisms for the same Qt apps. HyKr sets `QT_QPA_PLATFORMTHEME=qt6ct` and generates `qt6ct-colors.conf`, so a dropped-in `kdeglobals` would be inert at best. |

Three smaller divergences:

- **Border gradient.** Upstream's `col.active_border` is an 8-stop
  gradient. `apply-theme.sh` renders `{{border_active}}` as a single
  `rgba()` because Hyprland's Lua config validates that field as one
  colour, not as hyprlang's gradient string. The flat accent colour is
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
