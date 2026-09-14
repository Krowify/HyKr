# `quickshell -c hyperspace`

The Hyperspace theme's whole shell: a three-island top bar on every screen,
a native notification daemon with toasts, and four popup panels. It runs
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

## The bar

One full-width, fully transparent layer surface per screen, with three
opaque islands drawn inside it:

| Island | Contents |
| --- | --- |
| Left | Workspaces 1–5. The active one stretches into a bar; a workspace with windows on it is a brighter dot than an empty one. Click to switch. |
| Centre | `hh:mm`, a hairline, then `ddd d MMM`. |
| Right | Battery (icon + %), volume, network, bluetooth, notifications. |

Why one surface and not three: three PanelWindows would be three layer-shell
surfaces to keep in sync, and Quickshell is unreliable about piles of
PanelWindows (see `shell.qml`'s header). The gaps between the islands are
genuinely transparent, and the theme's `hyprland.lua.tpl` blurs this
namespace with `ignore_alpha = 0.2` — above the islands' 0.55 alpha, below
the gaps' 0 — so only the islands are blurred.

Battery leads the right island rather than sitting mid-row because it's the
only item whose width changes at runtime, and the island grows leftwards
from the screen edge: with it first, nothing to its right ever shifts.

## The panels

Click an icon in the right island and its panel drops directly underneath
it. `DockBar.anchorFor()` measures the tapped icon's distance from the
screen's right edge out of the island's live layout and hands it to
`DockState`, which each panel turns into its own right margin (clamped so a
panel near a screen edge stays on screen). Nothing here carries a hardcoded
per-icon offset the way the Laptop dock does, so re-ordering the row or
changing a glyph can't quietly misplace a panel.

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
