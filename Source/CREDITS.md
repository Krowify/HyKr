<div align="center">

# Credits

_HyKr wouldn't exist without the projects, tools, and artists below._

</div>

---

## Inspiration

- [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE) — repo/Scripts layout and README style this project follows.
- [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles) (GPLv3) — source of the wallpapers, and the waybar, wofi, swaync, hyprlock, nvim, starship, pywal (`wal/`), and wlogout configs, plus `hypr/wallpaper.sh` and `hypr/hypridle.conf` (both adapted — see `Configs/configs/README.md`). `hypr/hyprland.lua` is original, written for this repo.
- [43PR/dotfiles](https://github.com/43PR/dotfiles) (no license file upstream; kept for personal desktop use) — reference for the `minimal` theme (waybar module layout, wallpaper) and the quickshell wallpaper picker (`Configs/configs/quickshell/wallpaper-picker/`, adapted from their `hyprquickpaper`). Spicetify theming was rebuilt from scratch as original `color.ini`-based recoloring (spicetify's own stock-theme mechanism) rather than reusing their vendored CSS theme, which is a separate third-party author's work with no visible license.
- [Darkkal44/qylock](https://github.com/Darkkal44/qylock) (GPLv3) — source of the `pixel-sakura` SDDM theme.
- [dharmx/walls](https://github.com/dharmx/walls) — source of the themed wallpaper packs (no license file upstream; kept for personal desktop use, per-image credit unknown/unlisted upstream).
- [Hyprland](https://hyprland.org/) — the Wayland compositor this setup is built around.
- [tiesen243/dotfiles](https://github.com/tiesen243/dotfiles) — reference for the `firewalld` hardening posture in `Scripts/extra/setup_firewall.sh` (deny incoming / allow outgoing / log denials), adapted from their `ufw` setup since this repo uses `firewalld` instead.
- [Krowify/arch-install](https://github.com/Krowify/arch-install) — the previous, proven install this repo replaces. The sysctl anti-spoofing rules, `/etc/host.conf`, and `fail2ban` jail in `setup_firewall.sh` are carried over from its stage 4 (firewall-agnostic, so they apply regardless of ufw vs firewalld). `install.sh`'s root-to-regular-user handoff (create-user-if-missing, `visudo`-validated sudoers edits) and `install_gpu_drivers.sh`'s lspci-based GPU detection follow the same patterns as its `install.sh`/stage 1, adapted to run non-interactively and as a single re-exec rather than per-stage `su -c` calls.
- [enes-less/theme-switcher](https://github.com/enes-less/theme-switcher) (no license file upstream; kept for personal desktop use) — source of `Configs/configs/theme-switcher/`, giving `Super+Shift+T` a real theme picker across Hyprland/Waybar/Wofi/Kitty/Fastfetch/Starship/Hyprlock/SwayNC/Wlogout. `swww` calls patched to `awww`; a `de_symlink` step was added to `apply-theme.sh` since it writes directly into paths this repo symlinks whole-directory into `Configs/configs/` — see `Configs/configs/README.md` for why that mattered.

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

`Configs/configs/quickshell/hykr/shell.qml` (widget panel, `Super+M`) and
`Configs/configs/hypr/quick_settings.sh` (wofi menu, `Super+S`) are
original — written for this repo, not sourced from any of the repos above.
The panel was originally built in Eww, then rebuilt in Quickshell — see
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), whose own
shell explicitly replaced an earlier Eww/AGS attempt with Quickshell.

## Tools & Packages

- [eylles/pywal16](https://github.com/eylles/pywal16) — 16-color fork of [dylanaraps/pywal](https://github.com/dylanaraps/pywal), installed (`python-pywal16`) instead of plain `python-pywal` because it's what provides the `--cols16` flag used in `wallpaper.sh`/`link_dots.sh` to guarantee a full 16-color palette from any wallpaper.

---

<div align="right">
  <sub><a href="../README.md">← back to README</a></sub>
</div>
