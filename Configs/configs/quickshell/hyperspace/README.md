# `quickshell -c hyperspace`

The Hyperspace theme's whole shell: a top bar on every screen — in one of
two styles, a dynamic notch or three floating islands — a native
notification daemon with toasts, and four popup panels. It runs
*instead of* waybar + swaync — the theme's `theme.json` says so:

```json
"bar": "quickshell-dock",
"quickshell": { "config": "hyperspace" }
```

`theme-switcher/apply-theme.sh` reads those two on a theme switch,
`hypr/start_bar.sh` on login and on `Super+Ctrl+B`, and `hypr/dock_ipc.sh`
when a keybind needs to talk to the running shell. None of them hardcode a
config name, so adding another Quickshell-based theme needs no changes to
any of them.

## Two bars, one switch

`DockState.barStyle` picks which bar this shell runs. `shell.qml` gives the
unselected one an empty `Variants` model, so it builds no window at all.

```qml
property string barStyle: "notch"   // or "islands"
```

Changing it needs a restart of the shell, not a theme re-apply:

```shell
pkill -f 'quickshell -c hyperspace'; quickshell -c hyperspace
```

Both draw on one full-width, fully transparent layer surface per screen, and
both are blurred through `ignore_alpha = 0.2` in the theme's
`hyprland.lua.tpl` — above the 0.55 alpha their opaque parts paint at, below
the 0 of the empty space around them, so the compositor blurs the bar and
leaves the wallpaper either side of it alone. One surface rather than
several also sidesteps Quickshell's unreliability with piles of PanelWindows
(see `shell.qml`'s header).

### `notch` — NotchBar.qml

One capsule hanging off the top edge. At rest it carries `hh:mm` and the
workspace pips. It opens when you hover it, when a popup panel is up, and
for 2.6s whenever something changes — volume or mute, battery going low or
being plugged in, a bluetooth device connecting, the network or VPN state
moving, a notification arriving. Whatever changed is drawn in the accent for
as long as it's held open, so the notch says *what* happened rather than
just opening.

Expanded, it adds a wing each side: volume, network and bluetooth on the
left; battery, notifications and the date on the right.

How it fits, which is the whole design:

- The capsule is `[ left wing ][ clock + workspaces ][ right wing ]` in one
  centred Row. The centre group is always visible and **never moves** —
  both wings take the width of the *wider* of the two contents, so the
  capsule grows symmetrically around the clock instead of sliding the time
  sideways every time it opens.
- Only the wing widths animate. The capsule is sized to its content row, so
  it follows them; one animation drives the whole gesture.
- Each wing clips its own content and anchors it to the edge nearest the
  centre, so icons slide out from behind the clock rather than appearing
  mid-word.
- Total width is clamped to the output minus `islandMargin` either side, so
  a narrow screen gets a capsule that stops at the edges.
- The layer surface is a fixed 30px — the same as the exclusive zone — and
  the capsule only grows sideways. A surface that resized every frame would
  have the compositor re-laying-out the output 60 times a second.
- Its top corners are square because they're clipped off above the screen
  edge, not because of per-corner radii (which need a newer Qt than this
  assumes). It reads as hanging off the edge rather than floating below it.

### `islands` — DockBar.qml

Three opaque islands on that same transparent surface:

| Island | Contents |
| --- | --- |
| Left | Workspaces 1–5. The active one stretches into a bar; a workspace with windows on it is a brighter dot than an empty one. Click to switch. |
| Centre | `hh:mm`, a hairline, then `ddd d MMM`. |
| Right | Battery (icon + %), volume, network, bluetooth, notifications. |

Battery leads the right island rather than sitting mid-row because it's the
only item whose width changes at runtime, and the island grows leftwards
from the screen edge: with it first, nothing to its right ever shifts.

## The panels

Click an icon in either bar and its panel drops directly underneath it.
Each bar's `anchorFor()` measures the tapped icon's distance from the
screen's right edge — from the island's live layout, or, in the notch, from
the icon's mapped window position, since a capsule's icons move as it opens
— and hands it to `DockState`, which each panel turns into its own right
margin (clamped so a panel near a screen edge stays on screen). Nothing
carries a hardcoded per-icon offset the way the Laptop dock does, which is
what lets the same four panels serve both layouts.

| Icon | Left click | Right click |
| --- | --- | --- |
| Volume | Level, drag-to-set bar, mute | — |
| Network | Current connection + ProtonVPN (connect/disconnect via `protonvpn-cli`, or open the GUI app) | NetworkManager (`nm-connection-editor`, else `kitty nmtui`) |
| Bluetooth | Adapter on/off, known devices (tap a row to connect/disconnect), open blueman-manager | — |
| Bell | History, Do Not Disturb, clear all | — |

## Colours

Everything is read from `colors.json` in this directory, which is
**generated**, not hand-maintained:

- `theme-switcher/apply-theme.sh` writes it from the active theme's palette
  (which matugen has just derived from the wallpaper)
- `hypr/apply_wallpaper.sh` writes it from pywal's palette on a plain
  wallpaper pick

Last write wins, exactly as for kitty and starship. `Colors.qml` watches the
file, so the dock repaints the moment either script writes — no restart, no
theme re-apply. It also floors the accent's luminance upward (an accent from
a dark wallpaper would otherwise vanish against a dark island) and the
background's downward (so a light-ish generated background still reads as a
dark translucent island), which is why nothing here uses the raw values.

The committed `colors.json` is only a seed for a fresh install; on a live
machine it is whatever the last theme apply or wallpaper pick generated, so
`Scripts/sync_configs.sh` skips it.

## Why `services/` is duplicated from `../laptop/services/`

A Quickshell *config* resolves its singletons and relative imports inside
its own root, so two configs can't share one copy of a file without reaching
outside that root. `AudioService`, `BatteryService`, `NetworkService` and
`NotificationService` are therefore byte-identical copies plus a header
noting the duplication; `BluetoothService` additionally has per-device
connect/disconnect and a slower idle poll (the Laptop bar's icon reads only
adapter power, Hyperspace's also shows whether anything is connected).

**A fix to polling or output parsing in either copy belongs in both.** Each
file's header says so too.
