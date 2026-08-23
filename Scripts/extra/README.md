# extra

Optional/supporting scripts that aren't part of the core dotfiles
install (package lists, post-install helpers, maintenance utilities).

- [`install_sddm_theme.sh`](install_sddm_theme.sh) — installs
  `Configs/sddm/pixel-sakura` system-wide as the active SDDM theme.
  Separate from `link_dots.sh` because it targets `/usr/share/sddm`,
  not `$HOME`, and needs `sudo`.
- [`setup_firewall.sh`](setup_firewall.sh) — system hardening: `firewalld`
  (deny incoming by default, allow outgoing, log denials; removes ssh/mdns/
  samba-client/dhcpv6-client from the public zone — re-add whatever you
  actually need), sysctl anti-spoofing rules, `/etc/host.conf`, and
  `fail2ban` (sshd jail, inert until sshd is actually enabled). Chose
  firewalld over ufw specifically for its NetworkManager zone integration —
  this runs on both a desktop and a laptop that moves between networks;
  see the note it prints about assigning trusted networks a looser zone.
  Needs `sudo`.
