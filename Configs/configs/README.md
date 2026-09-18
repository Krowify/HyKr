# configs

Dotfiles destined for `~/.config`. Each subfolder here mirrors the name
of the application it configures, so it can be symlinked directly into
`~/.config/<app>` — see [`../../Scripts/link_dots.sh`](../../Scripts/link_dots.sh).

Currently sourced from [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles):

- `waybar/`, `wofi/`, `swaync/`, `nvim/`, `starship.toml`, `wal/`, `wlogout/`
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
- `quickshell/hykr/shell.qml` — quick-settings widget panel (Wi-Fi/Bluetooth/
  Night Light toggles, volume/brightness sliders, lock/logout/theme buttons),
  bound to `Super+M`. Originally built in Eww, rebuilt in Quickshell to
  mirror end-4/dots-hyprland's own move off Eww. Static dark palette, not
  pywal-linked. Written against Quickshell's documented QML API but not
  runtime-tested — no `quickshell` binary in the dev environment this was
  built in; the `Process`/polling blocks are the most likely thing to need
  fixing if something doesn't work.
- `quickshell/laptop/` — the Laptop theme's whole bar stack, replacing
  waybar + swaync with one process (`quickshell -c laptop`): a horizontal
  top dock per screen (workspaces, clock, battery/volume/network/bluetooth/
  date/notifications — hover the battery for the exact percentage), four
  popup panels, and a native notification daemon with a toast stack. Exposes an `IpcHandler` on target `dock`
  (reached through `hypr/dock_ipc.sh`) so `Super+N` and the quick-settings
  DND entry hit it under this theme instead of the swaync-client they still
  use everywhere else. Same not-runtime-tested caveat as
  `quickshell/hykr/` above.
- `quickshell/hyperspace/` — the Hyperspace theme's bar stack
  (`quickshell -c hyperspace`), same idea as `laptop/` but coloured entirely
  from the wallpaper: it reads a full generated palette from its own
  `colors.json`, not just an accent. Ships two bar layouts, switched by the
  one `DockState.barStyle` line: `notch`, a capsule hanging off the top edge
  that widens around a fixed clock when something changes and collapses
  again (the default), and `islands`, three floating pills across the top.
  Panels drop under whichever icon was clicked, measured from the live
  layout rather than hardcoded offsets, which is what lets one set of panels
  serve both. Every .qml but the services sits in the config root: reached
  through a `panels/` subdirectory instead, exactly one panel per launch
  failed to register as a type, a different one each time — see that
  directory's README. Its `services/` are copies of `laptop/services/` — a
  Quickshell config can't import across config roots — so a fix in one
  belongs in both; see `quickshell/hyperspace/README.md`. Same
  not-runtime-tested caveat.
- `hypr/apply_wallpaper.sh` — the shared colour pipeline behind every
  wallpaper picker in the repo: awww, pywal, then kitty (live, over its
  socket), starship, rofi, wofi, the Quickshell dock palettes, the Hyprland
  border, VS Code and spicetify. VS Code gets a generated colour-theme
  *extension* (`~/.vscode/extensions/hykr-theme/`), not
  `workbench.colorCustomizations` — customizations paint over whatever theme
  is selected, which made VS Code's own theme picker appear broken. Its
  `settings.json` is *merged* into, not overwritten: it is a file you own too,
  and every preference changed in VS Code's UI lands in it.
- `hypr/lock.sh` — the single path to a locked session: `Super+L`, wlogout's
  Lock button, `quick_settings.sh` and hypridle's `lock_cmd` (so
  `loginctl lock-session` and the pre-suspend hook too) all run it. Refuses
  to stack a second hyprlock, and once you unlock calls `start_bar.sh` to
  bring back the active theme's bar — a Quickshell dock doesn't always
  survive hyprlock's session-lock surface, and nothing else supervises it.
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
  active theme runs (`toggle-notifications`, `toggle-dnd`), falling back to
  `swaync-client` under the waybar themes. Used by `Super+N` and the
  quick-settings DND entry, which previously hardcoded
  `quickshell -c laptop` and so did nothing under any other Quickshell theme.
- `hypr/quick_settings.sh` — lightweight wofi menu (`Super+S`) wrapping
  existing actions (wallpaper picker, hyprlock, wlogout, hyprsunset/
  hypridle toggles) plus Wi-Fi/Bluetooth/DND toggles with no dedicated keybind.
- `hypr/fn_keys.sh` — the three laptop function-row actions that need a
  device name looked up first (keyboard backlight, touchpad toggle, airplane
  mode), so they can't be a one-line `exec_cmd` in `hyprland.lua`. Finds the
  `*kbd_backlight` device via `brightnessctl -l`, the touchpad via `hyprctl
  devices`, and toggles radios with nmcli + bluetoothctl rather than rfkill
  (`/dev/rfkill` is root-only, so an rfkill bind fails silently on a
  keypress). Always exits 0 — these are bound to hardware keys that may not
  emit a keycode at all on a given machine.
- `hypr/start_bar.sh` — picks the bar + notification daemon from the theme
  that's actually active (`current-theme.json` → that theme's `theme.json`
  `bar` and `quickshell.config` fields) instead of hardcoding one: `waybar`
  + `swaync` for most themes, `quickshell -c <config>` for a theme with
  `"bar": "quickshell-dock"` (Laptop, Hyperspace). It also stops any other
  theme's Quickshell shell, so switching between two of them can't stack
  two bars. Run from `hyprland.lua`'s autostart, and with
  `--toggle` from `Super+Ctrl+B`, both of which used to start waybar
  unconditionally — which is why waybar kept reappearing on top of the
  Quickshell dock after every login.
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
  into `hypr/`, `wofi/`, `kitty/`, `waybar/`, `swaync/`, `wlogout/`,
  `fastfetch/`, and `starship.toml` — all paths `link_dots.sh` symlinks
  *whole-directory* from this repo. Applying a theme unmodified would
  write straight through those symlinks and silently overwrite this
  repo's own tracked files on disk. Added a `de_symlink` step at the top
  of `apply-theme.sh` that converts each target from "symlink into the
  repo" to a real, independent copy the first time a theme is applied —
  after that, theme-switcher owns those live configs, same as it would
  for anyone installing this tool standalone, and the repo's own copies
  stay untouched.
