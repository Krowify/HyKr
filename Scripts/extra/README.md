# extra

Optional/supporting scripts that aren't part of the core dotfiles
install (package lists, post-install helpers, maintenance utilities).

- [`install_sddm_theme.sh`](install_sddm_theme.sh) — installs
  `Configs/sddm/pixel-sakura` system-wide as the active SDDM theme.
  Separate from `link_dots.sh` because it targets `/usr/share/sddm`,
  not `$HOME`, and needs `sudo`.
