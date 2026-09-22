# extra

Optional/supporting scripts that aren't part of the core dotfiles
install (package lists, post-install helpers, maintenance utilities).

- [`install_sddm_theme.sh`](install_sddm_theme.sh) — installs
  `Configs/sddm/pixel-sakura` system-wide as the active SDDM theme.
  Separate from `link_dots.sh` because it targets `/usr/share/sddm`,
  not `$HOME`, and needs `sudo`.
- [`hide_avahi_launchers.sh`](hide_avahi_launchers.sh) — keeps avahi's
  `bvnc`/`bssh`/`avahi-discover` launchers out of wofi. avahi is pulled in
  as a dependency, so instead of uninstalling it this adds a `NoExtract`
  line to `/etc/pacman.conf` and deletes any copies already on disk.
  Idempotent; run by `install.sh` before packages. Needs `sudo`.
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
  resume setup — though `hykr-suspend-refresh.service`, which this script
  installs and enables, now does that re-check on every boot for you
  (`--refresh` is the quiet non-interactive mode it runs).
  Both the battery and external-power lid cases get
  `suspend-then-hibernate` where hibernation works; `HibernateOnACPower=no`
  keeps a plugged-in machine merely suspended until the charger comes out,
  which closes the "closed the lid on AC, unplugged it later, came back to
  a flat battery" hole. `HandleLidSwitchDocked` stays `ignore` so the lid
  can be shut while driving an external monitor — `logind` counts any
  connected display as docked, so the backstop for that is
  `hypr/idle_sleep.sh` (see `Configs/configs/hypr/`), not this script.
  `HibernateDelaySec` defaults to 15min — only ever reached on battery, so
  it is the bound on what a lid closed off the charger costs; override for
  one run with `HYKR_HIBERNATE_DELAY=45min`, or edit `HIBERNATE_DELAY` near
  the top of the script to change it for good.
  Also reports whether an RTC wake alarm exists and is writable, since
  `suspend-then-hibernate` needs one to wake itself up and finish.
  Needs `sudo`.
- [`setup_blackarch.sh`](setup_blackarch.sh) — adds the BlackArch
  repository to this install, without installing any tools. BlackArch is a
  pacman repo overlay, not a distro to migrate to, so every HyKr config
  keeps working; what can actually break the desktop is precedence. The
  script backs up `pacman.conf` and the explicit package list, insists on a
  full `-Syu` first (a third-party repo on a stale system is how an
  accidental partial upgrade happens), prints `strap.sh`'s SHA1 for you to
  check against the published one rather than baking in a checksum that
  would go stale, then **refuses to continue unless `[blackarch]` is the
  last repo section** — placed higher, BlackArch's rebuilds of ordinary
  packages outrank the official ones. It then reports which packages
  BlackArch also ships, reading the watch list straight out of
  `pkg_core.lst`/`pkg_extra.lst` so it stays current, and calls out
  `python-pywal16` by name because it provides/replaces `python-pywal` and
  a silent swap would cost the `--cols16` flag every theme-switcher
  template depends on. `--report-only` re-runs just that report on an
  already-strapped system; `--install "blackarch-recon blackarch-webapp"`
  installs category groups. Never installs the bare `blackarch` group.
  Needs `sudo`.
