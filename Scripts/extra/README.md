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
- [`setup_suspend.sh`](setup_suspend.sh) — lid-close power management:
  diagnoses what this machine's firmware offers (`/sys/power/mem_sleep`),
  whether hibernation is actually possible, and whether anything is
  blocking sleep, then writes explicit `logind`/`sleep` drop-ins for it —
  `HandleLidSwitch=suspend-then-hibernate` where hibernation works,
  plain `suspend` where it doesn't (and a checklist of what's missing).
  Offers to switch an s2idle-by-default machine to `deep` (S3) via a
  `tmpfiles.d` drop-in, which is the usual fix for a laptop that goes flat
  with the lid shut. `--check` diagnoses and writes nothing. No-ops on a
  desktop (no battery, no lid). Reports separately on whether the machine
  can *resume* from hibernation (`resume=` + initramfs hook, or systemd
  255+ on EFI writing a HibernateLocation variable) — logind's own
  `CanHibernate` only answers whether the image can be written, so an
  unset `/sys/power/resume` alongside `CanHibernate=yes` is worth a manual
  `systemctl hibernate` test. When it finds no resume route, it prints the
  steps for *this* machine — the swap in use, the UUID (and offset, for a
  swapfile) `resume=` wants, where the kernel command line lives on this
  bootloader, and whether HOOKS already covers resume. It prints those
  commands rather than running them: a bad kernel command line is the one
  change here that can leave a machine unbootable. Run it again after a
  reboot if the first
  run happened inside `arch-chroot`, and after any change to swap or the
  resume setup. Needs `sudo`.
