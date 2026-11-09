# configs

Dotfiles destined for `~/.config`. Each subfolder here mirrors the name
of the application it configures, so it can be symlinked directly into
`~/.config/<app>` — see [`../../Scripts/link_dots.sh`](../../Scripts/link_dots.sh).

Currently sourced from [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles):

- `nvim/`, `starship.toml`, `wal/`, `wlogout/` (the `wofi/` config that came
  from here too is gone: the desktop shell's launcher and pickers replace it)
- `hypr/` — `hyprlock.conf` as-is; `hyprland.lua` is ours (keybinds); `hypridle.conf`
  and `wallpaper.sh` are adapted (dropped references to things not in this repo:
  a `cava` config, an unrecognized `hyprdvd` tool, a hardcoded Spotify path)
- `kitty/kitty.conf` — trimmed to just elifouts' actual settings (font, padding,
  tab style); their `kitty.conf` was mostly kitty's own 95KB stock template,
  not worth carrying over. `current-theme.conf` ships a fallback pywal theme.
- `zsh/.zshrc` — ours, not elifouts' (they're on bash anyway, with aliases and
  tools we don't have: Docker, zoxide, ncspot, sound-effect-on-error hooks).
  Activates starship, runs fastfetch, wires up fzf plus the zsh-autosuggestions/
  zsh-syntax-highlighting/zsh-completions plugins from `pkg_core.lst`.

Not from elifouts:

- `gtk-3.0/`, `gtk-4.0/` — `settings.ini` activating Materia-dark/Qogir-dark
  (the packages existed in `pkg_core.lst` before, nothing applied them)
- `fastfetch/config.jsonc` — ours, minimal, auto-detects the distro logo
- `quickshell/hykr/` — the desktop shell (`quickshell -c hykr`): everything
  that isn't the bar, always running beside it in a process of its own, so a
  QML error in either can't take the other down. `start_bar.sh` starts it
  (with the same start-up check as the bar, logging to
  `$XDG_RUNTIME_DIR/hykr-desktop.log`) and keybinds reach it over IPC
  through `hypr/hykr.sh <target>`, starting it first if it isn't up:
  - `Launcher.qml` — app launcher (`Super+Tab`), from Quickshell's own
    `DesktopEntries`; ranks by match quality, then how often you launch each
    app (counts in `~/.local/state/hykr/launcher.json`). Terminal apps open
    in kitty.
  - `ClipboardPicker.qml` — clipboard history (`Super+V`) over `cliphist`
    (which still records it): Enter copies, Delete removes, image entries
    are decoded into a preview pane.
  - `WallpaperPicker.qml` — wallpaper picker (`Super+Shift+W`): a thumbnail
    grid of `~/wallpapers` that runs `hypr/apply_wallpaper.sh` on the pick.
    Thumbnails are made once by `thumbs.sh` (ImageMagick) into
    `~/.cache/hykr/thumbs/`, keyed by path. Replaces the separate
    `quickshell/wallpaper-picker` config and `wallpaper.sh`'s rofi/wofi menu
    (`wallpaper.sh` now just opens this).
  - `ThemePicker.qml` — theme picker (`Super+Shift+T`, `themes.sh` lists the
    themes): a card per theme previewed with its wallpaper. A theme whose
    colours come from its wallpaper opens the wallpaper picker on its own
    wallpapers -- and so does `apply-theme.sh <theme>` given no wallpaper.
    Replaces `theme-picker.sh`'s rofi/wofi menu (it now just opens this).
  - `ControlCentre.qml` — control centre (`Super+M`, `Super+S`), top-right
    under the bar: Wi-Fi / Bluetooth / Do Not Disturb / Caffeine / Night
    Light / Airplane tiles, volume and brightness sliders, CPU/RAM/disk, the
    playing MPRIS track with controls, and the notification count (opening
    the bar's notification centre -- notifications stay in the bar's
    process). `status.sh` reads all of it in one pass, every 2s, only while
    the panel is open. Replaces the old `Super+M` panel and the `Super+S`
    wofi menu (`hypr/quick_settings.sh`).
  - `AudioPanel.qml`, `BluetoothPanel.qml`, `NetworkPanel.qml` — quick
    panels opened by every bar's volume / Bluetooth / network icon (and the
    chevrons in the control centre), styled like it (`QuickPanel.qml`,
    `ListRow.qml`, `LevelSlider.qml`). Sound: output and mic volume, choose
    the output / input, per-app volume (`audio.sh`, pactl). Bluetooth: power,
    connect / disconnect / forget, scan and pair (`bluetooth.sh`,
    bluetoothctl). Network: Wi-Fi on/off, join a network with the password
    typed in place, forget saved ones, wired status, ProtonVPN (`wifi.sh`,
    nmcli). Blueman / nm-connection-editor stay a link away for what these
    don't cover (a PIN-pairing keyboard, enterprise Wi-Fi).
  - `Osd.qml` — on-screen display for the volume, mic and brightness keys
    (`hypr/osd.sh` makes the change, then calls it over IPC): a click-through
    pill near the bottom of the focused screen, gone 1.5s after the last key.
  - `Theme.qml` / `colors.json` — palette, rewritten by `apply-theme.sh` and
    `apply_wallpaper.sh` like every bar's; `qs-stop.sh` excludes this config
    so a theme switch never mistakes it for a bar.
- `quickshell/laptop/` — the Sakura and Default themes' whole bar stack,
  bar and notifications in one process (`quickshell -c laptop`): a horizontal
  top dock per screen (workspaces, clock, battery/volume/network/bluetooth/
  date/notifications — hover the battery for the exact percentage — and a
  cog opening the desktop shell's control centre). In the islands layout a
  fourth island carries the playing MPRIS track (art, title, previous /
  play-pause / next, a progress line) whenever there is a player and room
  for it before the clock island. Volume, network and Bluetooth open the
  desktop shell's quick panels; the notification centre and a native
  notification daemon with a toast stack stay in this process. Exposes an `IpcHandler` on target `dock`
  (reached through `hypr/dock_ipc.sh`) so `Super+N` and the quick-settings
  DND entry reach it. Same not-runtime-tested caveat as
  `quickshell/hykr/` above.
- `quickshell/bar/` — the shared, palette-driven bar stack
  (`quickshell -c bar`; was `quickshell/hyperspace/`), same idea as
  `laptop/` but coloured entirely from the theme: it reads a full generated
  palette from its own `colors.json`, not just an accent. The bar style is
  the theme's choice — `"quickshell": { "style": ... }` in theme.json, which
  apply-theme.sh writes to the shell's `style.json`: `notch`, a capsule
  hanging off the top edge that widens around a fixed clock when something
  changes and collapses again (Hyperspace, and the default); `islands`,
  three floating pills across the top; `pill`, one centred pill holding
  everything (Arch, Dynamic, Everforest, Graphite); and `stats`, three thin
  pills with CPU/GPU/RAM/temperature readings (Minimal).
  Panels drop under whichever icon was clicked, measured from the live
  layout rather than hardcoded offsets, which is what lets one set of panels
  serve both. Every .qml but the services sits in the config root: reached
  through a `panels/` subdirectory instead, exactly one panel per launch
  failed to register as a type, a different one each time — see that
  directory's README. Its `services/` are copies of `laptop/services/` — a
  Quickshell config can't import across config roots — so a fix in one
  belongs in both; see `quickshell/bar/README.md`. Same
  not-runtime-tested caveat.
- `hypr/apply_wallpaper.sh` — the shared colour pipeline behind every
  wallpaper picker in the repo: awww, pywal, then kitty (live, over its
  socket), starship, the Quickshell palettes (bars and desktop shell), the Hyprland
  border, VS Code and spicetify. VS Code gets a generated colour-theme
  *extension* (`~/.vscode/extensions/hykr-theme/`), not
  `workbench.colorCustomizations` — customizations paint over whatever theme
  is selected, which made VS Code's own theme picker appear broken. Its
  `settings.json` is *merged* into, not overwritten: it is a file you own too,
  and every preference changed in VS Code's UI lands in it.
- `hypr/lock.sh` — the single path to a locked session: `Super+L`, wlogout's
  Lock button, the control centre and hypridle's `lock_cmd` (so
  `loginctl lock-session` and the pre-suspend hook too) all run it. Refuses
  to stack a second hyprlock, and once you unlock calls `start_bar.sh` to
  bring back the active theme's bar — a Quickshell dock doesn't always
  survive hyprlock's session-lock surface, and nothing else supervises it.
- `hypr/restore_theme.sh` — puts back at login what the theme switcher last
  set. Runs from `hyprland.lua`'s autostart, before `start_bar.sh`. Two things
  were never restored on a relog: the **wallpaper** (the autostart started
  `awww-daemon` and stopped there — nothing ever ran `awww img`, so whether it
  came back was down to the daemon's own cache), and a **missing generated
  file**. `hyprland.lua` now `pcall`-requires `generated-theme.lua` and
  `colors-hyprland.lua` instead of hard-requiring them, so their absence no
  longer aborts the whole config — but it degrades to Hyprland's defaults, and
  this re-renders them. It deliberately does *not* re-apply a theme that does
  not need it: `apply-theme.sh` restarts bars and re-runs matugen, so that is
  the repair path, not the happy path. A dynamic theme with no resolvable
  wallpaper is skipped rather than re-applied, because invoked without one it
  opens a wallpaper picker — at login, a menu waiting for nobody.
- `hypr/monitors.lua` — per-machine monitor layout, **gitignored**, optional.
  `hyprland.lua` `pcall`-requires it and falls back to a bare
  `output = ""` catch-all when it is absent. Generate it with
  `Scripts/snapshot_monitors.sh` rather than by hand; `monitors.lua.example`
  documents the by-hand route. Worth having even on a single-monitor machine:
  the catch-all's `scale = "auto"` is a DPI-derived, often fractional scale,
  and neither scale nor rotation survives a `hyprctl reload` unless pinned
  here.
- `hypr/idle_sleep.sh` — the backstop that stops a closed lid costing a
  battery. `hypridle` on its own only notifies, locks and blanks the screen
  (DPMS off, which looks exactly like sleep), and `logind`'s lid switch is
  deliberately set to ignore the lid whenever an external display is
  connected — and `logind` counts a single HDMI cable as "docked". Between
  the two, nothing in this repo ever actually suspended a laptop sitting at
  a desk with the lid shut. `hypridle.conf` calls it twice: at
  900s with `--lid-closed-only`, which reads `/proc/acpi/button/lid` and
  acts only when the lid is physically shut, and at 3600s with no argument
  as the general "walked away with it open" backstop. A lid whose state
  cannot be read is never assumed closed — suspending a machine someone is
  using because a sysfs file is missing would be much worse than waiting
  for the general timeout, which still covers it. Both no-op on a desktop
  and on the charger, so the drive-a-monitor-with-the-lid-shut workflow
  still works, and off the charger they sleep the machine regardless of
  what the lid did. Asks for
  `suspend-then-hibernate` rather than plain `suspend` wherever `logind`
  says hibernation is possible — the hibernate half is a property of the
  sleep operation, so plain `suspend` here would bound nothing.
- `hypr/dock_ipc.sh` — calls a function on whichever Quickshell dock the
  active theme runs (`toggle-notifications`, `toggle-dnd`). Used by `Super+N` and the
  control centre's DND tile (and `is-dnd` / `count` for its notification
  card), which previously hardcoded
  `quickshell -c laptop` and so did nothing under any other Quickshell theme.
- `hypr/fn_keys.sh` — the three laptop function-row actions that need a
  device name looked up first (keyboard backlight, touchpad toggle, airplane
  mode), so they can't be a one-line `exec_cmd` in `hyprland.lua`. Finds the
  `*kbd_backlight` device via `brightnessctl -l`, the touchpad via `hyprctl
  devices`, and toggles radios with nmcli + bluetoothctl rather than rfkill
  (`/dev/rfkill` is root-only, so an rfkill bind fails silently on a
  keypress). Always exits 0 — these are bound to hardware keys that may not
  emit a keycode at all on a given machine.
- `hypr/start_bar.sh` — starts the bar + notification daemon of the theme
  that's actually active: `quickshell -c <config>`, from `current-theme.json`
  → that theme's `theme.json` `quickshell.config` field (default `laptop`).
  It also stops any other theme's Quickshell shell, so switching between two
  of them can't stack two bars, and any waybar/swaync left over from an older
  HyKr install. Run from `hyprland.lua`'s autostart, from `lock.sh` after an
  unlock, and with `--toggle` from `Super+Ctrl+B`.
- `hypr/KEYBINDS.md` — every bind in `hyprland.lua`, grouped the same
  way the file is, as Keybind/Action tables — a human-readable index,
  not copy-pasteable syntax (see `hyprland.lua` directly for that).
  Grouping mirrors [Krowify/arch-install's KEYBINDINGS.md](https://github.com/Krowify/arch-install/blob/main/KEYBINDINGS.md),
  built from this repo's own binds (not arch-install's — different app stack).
- `theme-switcher/` — from [enes-less/theme-switcher](https://github.com/enes-less/theme-switcher)
  (no LICENSE file upstream; kept for personal desktop use). Bound to
  `Super+Shift+T`, finally giving that keybind a real target. Patched
  `swww` → `awww` throughout (same rename every other script in this
  repo already accounts for). Its own `install.sh` wasn't used — it
  would've replaced `~/.config/hypr` wholesale with its own bundled
  config; only `theme-switcher/` (the actual theming engine) and
  `scripts/theme-picker.sh` were pulled in.

  **Important, HyKr-specific fix**: `apply-theme.sh` writes directly
  into `hypr/`, `kitty/`, `wlogout/`,
  `fastfetch/`, and `starship.toml` — all paths `link_dots.sh` symlinks
  *whole-directory* from this repo. Applying a theme unmodified would
  write straight through those symlinks and silently overwrite this
  repo's own tracked files on disk. Added a `de_symlink` step at the top
  of `apply-theme.sh` that converts each target from "symlink into the
  repo" to a real, independent copy the first time a theme is applied —
  after that, theme-switcher owns those live configs, same as it would
  for anyone installing this tool standalone, and the repo's own copies
  stay untouched.
