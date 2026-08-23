<div align="center">

# Credits

_HyKr wouldn't exist without the projects, tools, and artists below._

</div>

---

## Inspiration

- [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE) — repo/Scripts layout and README style this project follows.
- [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles) (GPLv3) — source of the wallpapers, and the waybar, wofi, swaync, hyprlock, nvim, starship, pywal (`wal/`), and wlogout configs, plus `hypr/wallpaper.sh` and `hypr/hypridle.conf` (both adapted — see `Configs/configs/README.md`). `hypr/hyprland.conf` is original, written for this repo.
- [Darkkal44/qylock](https://github.com/Darkkal44/qylock) (GPLv3) — source of the `pixel-sakura` SDDM theme.
- [dharmx/walls](https://github.com/dharmx/walls) — source of the themed wallpaper packs (no license file upstream; kept for personal desktop use, per-image credit unknown/unlisted upstream).
- [Hyprland](https://hyprland.org/) — the Wayland compositor this setup is built around.
- [tiesen243/dotfiles](https://github.com/tiesen243/dotfiles) — reference for the `firewalld` hardening posture in `Scripts/extra/setup_firewall.sh` (deny incoming / allow outgoing / log denials), adapted from their `ufw` setup since this repo uses `firewalld` instead.

## Wallpapers

| Wallpaper | Artist | Source |
| --- | --- | --- |
| Aloe.jpg, DSC02292-EDIT.jpg, DSC04822.JPG, DSC05767.JPG, MistyTrees.jpg, Sunset.jpg, dreamlike.jpg, leaves.jpg, pywallpaper.jpg | Eli F. ([elifouts](https://github.com/elifouts)) | [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles/tree/main/wallpapers) |
| `nord/`, `anime/`, `m-26.jp/`, `apocalypse/`, `outrun/`, `evangelion/`, `stalenhag/`, `pixel/`, `radium/` (554 images total) | Unlisted (repo has no per-image credits or LICENSE) | [dharmx/walls](https://github.com/dharmx/walls) |

## SDDM Theme

`pixel-sakura` in [`Configs/sddm/`](../Configs/sddm) is from
[Darkkal44/qylock](https://github.com/Darkkal44/qylock/tree/main/themes/pixel-sakura).

## GTK / Icon Theme

Widget theme `Materia-dark` and icon theme `Qogir-dark` are
[elifouts/Dotfiles](https://github.com/elifouts/Dotfiles)' documented
preference — installed as packages (`materia-gtk-theme`,
`qogir-icon-theme`), activated by `Configs/configs/gtk-{3,4}.0/settings.ini`
(ours — elifouts doesn't ship theme config files itself). Cursor theme
`illogical-impulse-bibata-modern-classic-bin` is from elifouts'
`fullinstall.sh` package list.

## Terminal / Shell

`Configs/configs/kitty/kitty.conf` keeps only elifouts' actual settings
(font, padding, tab style) — their file was mostly kitty's own stock
95KB default config template, not anything they wrote. `Configs/configs/bash/.bashrc`
is ours, not elifouts' — their `.bashrc` was built around tools this
repo doesn't have (Docker, zoxide, ncspot, custom sound-effect hooks).

## Quick Settings

`Configs/configs/eww/` (widget panel, `Super+M`) and
`Configs/configs/hypr/quick_settings.sh` (wofi menu, `Super+S`) are
original — written for this repo, not sourced from any of the repos above.

## Tools & Packages

- _TBD_

---

<div align="right">
  <sub><a href="../README.md">← back to README</a></sub>
</div>
