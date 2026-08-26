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
- `bash/.bashrc` — ours, not elifouts'. Their `.bashrc` was full of aliases and
  tools we don't have (Docker, zoxide, ncspot, sound-effect-on-error hooks);
  this one just activates starship and runs fastfetch.

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
- `hypr/quick_settings.sh` — lightweight wofi menu (`Super+S`) wrapping
  existing actions (wallpaper picker, hyprlock, wlogout, hyprsunset/
  hypridle toggles) plus Wi-Fi/Bluetooth/DND toggles with no dedicated keybind.
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
