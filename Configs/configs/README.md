# configs

Dotfiles destined for `~/.config`. Each subfolder here mirrors the name
of the application it configures, so it can be symlinked directly into
`~/.config/<app>` — see [`../../Scripts/link_dots.sh`](../../Scripts/link_dots.sh).

Currently sourced from [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles):

- `waybar/`, `wofi/`, `swaync/`, `nvim/`, `starship.toml`, `wal/`, `wlogout/`
- `hypr/` — `hyprlock.conf` as-is; `hyprland.conf` is ours (keybinds); `hypridle.conf`
  and `wallpaper.sh` are adapted (dropped references to things not in this repo:
  a `cava` config, an unrecognized `hyprdvd` tool, a hardcoded Spotify path)
