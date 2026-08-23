# configs

Dotfiles destined for `~/.config`. Each subfolder here mirrors the name
of the application it configures, so it can be symlinked directly into
`~/.config/<app>` — see [`../../Scripts/link_dots.sh`](../../Scripts/link_dots.sh).

Currently sourced from [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles):

- `waybar/`, `wofi/`, `swaync/`, `nvim/`, `starship.toml`, `wal/`, `wlogout/`
- `hypr/` — `hyprlock.conf` as-is; `hyprland.conf` is ours (keybinds); `hypridle.conf`
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
