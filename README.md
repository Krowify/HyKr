<div align="center">

# HyKr

<sub>_A built-from-scratch dotfiles repo for Arch Linux._</sub>

<br>

<a href="#structure"><kbd> <br> Structure <br> </kbd></a>&ensp;&ensp;
<a href="#installation"><kbd> <br> Installation <br> </kbd></a>&ensp;&ensp;
<a href="Source/wallpapers"><kbd> <br> Wallpapers <br> </kbd></a>&ensp;&ensp;
<a href="Configs/configs/hypr/KEYBINDS.md"><kbd> <br> Keybinds <br> </kbd></a>&ensp;&ensp;
<a href="Source/CREDITS.md"><kbd> <br> Credits <br> </kbd></a>

</div>
<br>

<a id="structure"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=STRUCTURE" width="450"/>

---

```
HyKr/
├── Configs/
│   ├── configs/   # dotfiles → ~/.config (waybar, wofi, swaync, hypr, nvim, starship.toml,
│   │               #   wal, wlogout, kitty, gtk-3.0, gtk-4.0, fastfetch, quickshell,
│   │               #   theme-switcher) + zsh/.zshrc → ~/.zshrc
│   ├── .local/    # dotfiles → ~/.local
│   ├── sddm/      # SDDM themes → /usr/share/sddm/themes (pixel-sakura)
│   └── networkmanager/ # conf.d drop-ins → /etc/NetworkManager/conf.d (MAC randomization)
├── Scripts/
│   ├── install.sh            # single entrypoint: root handoff -> GPU drivers -> packages ->
│   │                          #   link_dots -> enable_services -> SDDM theme -> firewall ->
│   │                          #   MAC randomization; prompts for gestures/sshd/usbguard
│   ├── install_gpu_drivers.sh # auto-detects the GPU (lspci), installs mesa and/or nvidia-open
│   ├── enable_services.sh    # enables sddm/NetworkManager/bluetooth/power-profiles — not optional
│   ├── global_fn.sh          # shared lib, sourced by every script
│   ├── link_dots.sh          # symlinks Configs/configs/* into $HOME per Scripts/dots manifest
│   ├── dots/                 # one .toml manifest per app (source → target)
│   ├── extra/                # optional/secondary scripts (install_sddm_theme.sh, setup_firewall.sh,
│   │                          #   setup_suspend.sh — lid/suspend power management)
│   ├── pkg_core.lst          # packages needed to run what's in Configs/
│   └── pkg_extra.lst         # optional apps (vesktop, spotify, proton mail)
└── Source/
    ├── wallpapers/  # shipped wallpapers (elifouts/Dotfiles + 9 themed packs from dharmx/walls)
    └── CREDITS.md   # attribution
```

> [!TIP]
> Each folder above has its own `README.md` explaining what belongs in it.

<div align="right">
  <sub><a href="#hykr">🡅 back to top</a></sub>
</div>

<a id="installation"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=INSTALLATION" width="450"/>

---

```shell
sudo pacman -Syu --needed --noconfirm git base-devel
git clone --depth 1 https://github.com/krowify/HyKr ~/HyKr
cd ~/HyKr/Scripts
./install.sh
```

> [!IMPORTANT]
> Run as root right after `pacstrap` (fresh install, no user yet)? `install.sh`
> prompts for a username, creates it if needed, moves this repo into their
> home directory (it was cloned as root, under `/root`), and re-execs the
> rest of itself as that user — everything past that point runs as a
> regular user with `sudo`, not as root.
>
> `install.sh` auto-detects your GPU and installs the matching driver,
> installs `yay` if missing, installs everything in `pkg_core.lst` and
> `pkg_extra.lst`, links the dotfiles, enables `sddm`/`NetworkManager`/
> `bluetooth`/`power-profiles-daemon` (not optional — skipping these means no
> login screen, no network, no bluetooth after reboot), installs the SDDM
> theme, applies the security hardening step (firewalld + sysctl
> anti-spoofing + fail2ban) and the NetworkManager MAC-randomization
> drop-in, and configures lid-close power management (see below). It then
> **asks** before each of: the Hyprland gesture plugins, disabling `sshd`,
> and `usbguard`.
>
> A package that fails to build no longer aborts the run — the installer
> warns, carries on, and lists every skipped step at the end, so a broken
> AUR package can't leave you with packages installed and no dotfiles linked.
>
> Firewalld denies all incoming by default on any untrusted network — if you
> SSH into this machine or use LAN file sharing, re-add what you need
> afterward:
> `sudo firewall-cmd --zone=public --add-service=ssh --permanent && sudo firewall-cmd --reload`
>
> Installing **over SSH**? The installer detects it and leaves `sshd` alone
> — disabling it would drop the session running the install. Run
> `Scripts/extra/disable_sshd.sh` yourself later, at the machine's console,
> if you want it off.
>
> Running this **inside `arch-chroot`, before your first reboot**? Services
> get `enable`d but not started (nothing's running yet to start them
> against), and firewalld's live zone config is skipped since it needs its
> own daemon running to talk to — both finish automatically after your
> first real boot, except firewalld: re-run `Scripts/extra/setup_firewall.sh`
> once you've rebooted to apply the zone/logging config.

<a id="firewall"></a>
### Activating the firewall on a live install

`setup_firewall.sh` is idempotent and safe to re-run any number of times.
On a booted system, this is the whole thing:

```shell
~/HyKr/Scripts/extra/setup_firewall.sh
```

That enables and starts `firewalld`, sets the default zone to `public`,
strips `ssh`/`mdns`/`samba-client`/`dhcpv6-client` out of it, turns on
denied-packet logging, writes `/etc/sysctl.d/90-hardening.conf` and
`/etc/host.conf`, configures the `fail2ban` sshd jail, and prints the
resulting zone. Run it **after a reboot** if the first attempt happened
inside `arch-chroot` — the script says so at the time, because
`firewall-cmd` can only talk to a running `firewalld` over D-Bus.

Just want the daemon up, without the rest of the hardening?

```shell
sudo systemctl enable --now firewalld
```

Check what's actually active at any point with:

```shell
sudo firewall-cmd --state        # "running"
sudo firewall-cmd --list-all     # zone, services, logging
```

<div align="right">
  <sub><a href="#hykr">🡅 back to top</a></sub>
</div>

<a id="suspend"></a>
### The laptop goes flat with the lid closed

Closing the lid suspends — that part is `systemd-logind`'s default and has
always worked. What decides whether a closed lid *costs* anything is which
sleep state the firmware gives you, and most laptops built since ~2019 only
offer `s2idle` ("modern standby"), where the machine stays powered and
relies on every device idling properly. One that doesn't, and a full battery
is gone in an afternoon with the lid shut.

```shell
~/HyKr/Scripts/extra/setup_suspend.sh --check   # diagnose, change nothing
~/HyKr/Scripts/extra/setup_suspend.sh           # apply
~/HyKr/Scripts/extra/setup_suspend.sh --refresh # re-apply quietly (what the boot unit runs)
```

`--check` prints the sleep states the firmware offers, whether hibernation
is possible, the lid settings currently in force, and anything holding a
block inhibitor on sleep (which stops a lid close doing *anything* — no
config overrides that; quit the program holding it).

Applying writes two drop-ins: `/etc/systemd/logind.conf.d/10-hykr-lid.conf`
pins all three lid cases (battery / external power / docked), and, where
hibernation is actually possible,
`/etc/systemd/sleep.conf.d/10-hykr-sleep.conf` sets
`HibernateDelaySec=15min` so `suspend-then-hibernate` keeps instant resume
for a coffee break and writes RAM to swap for anything longer. Paired with
`HibernateOnACPower=no` that delay is only ever reached on battery, so it is
the bound on what a lid closed away from the charger can cost. Raise it with
`HYKR_HIBERNATE_DELAY=45min ~/HyKr/Scripts/extra/setup_suspend.sh` if losing
instant resume annoys you more than the drain does (edit the default at the
top of the script to make it stick, since the boot unit re-reads it there). Hibernation is
only turned on once `logind` itself confirms it can — an unbootable
`suspend-then-hibernate` leaves the machine awake with the lid shut, which
is the very thing being fixed. When it can't, the script prints the
checklist (swap size, `resume=`, initramfs hook) and leaves plain `suspend`
in place. That checklist is also what makes wlogout's Hibernate button work.

The script ends by printing, in plain terms, what a closed lid will now
actually do on this machine — worth reading, because three drop-ins
interact to decide it:

| Situation | What happens |
| --- | --- |
| Lid closed, on battery | suspend, then hibernate after 15 min |
| Lid closed, on the charger | suspend, and stay suspended — until the charger comes out, at which point the 15 min clock starts applying |
| Lid closed, external monitor attached | nothing from `logind`; `idle_sleep.sh` sleeps it after 15 min, so hibernation ~30 min after the lid shuts — see below |

**On the charger is not a special case any more.** It used to be pinned to
plain `suspend`, on the reasoning that the battery isn't the clock while
you're plugged in. That only holds while the cable stays in: which sleep
you get is decided once, at lid-close time, so closing the lid plugged in
and *then* unplugging left the machine in s2idle on battery with no
hibernate timer at all. Both cases now get `suspend-then-hibernate`, and
`HibernateOnACPower=no` (systemd 254+) is what keeps a genuinely plugged-in
machine merely suspended instead of hibernating it 15 minutes into every
coffee break.

**A single HDMI cable disables the lid switch.** `HandleLidSwitchDocked`
stays `ignore` so the laptop can drive an external monitor with the lid
shut — but `logind` counts *any* connected external display as "docked",
not just a real dock. Nothing else in this repo ever suspended, and
`hypridle` only notifies, locks and blanks the screen, so a laptop at a
desk with the lid closed used to run until the battery was gone behind a
dark screen that looked exactly like sleep. The backstop is
`~/.config/hypr/idle_sleep.sh`, wired into `hypridle.conf` twice: at 900s
in `--lid-closed-only` mode, which acts only when the lid is physically
shut, and at 3600s as a general backstop for "walked away with it open".
Both no-op on a desktop and on the charger, so the drive-a-monitor-lid-shut
workflow is untouched; off the charger they sleep the machine regardless of
what the lid did. Both ask for `suspend-then-hibernate` wherever that
works, so the bound holds on s2idle-only firmware too.

That makes the docked case 15 min awake plus 15 min suspended — hibernated
roughly half an hour after the lid shuts, rather than the hour and a
quarter it would take if the lid had to wait for the general timeout.

**It re-checks itself at every boot.** Whether hibernation is possible
depends on facts that change after install — swap added later, swap that
turns out to be zram (which can't hold a hibernation image), `resume=`
finally making it onto the kernel command line. `install.sh` runs this once
on a fresh machine, so a laptop that couldn't hibernate that day used to
keep `HandleLidSwitch=suspend` forever. `hykr-suspend-refresh.service` now
re-runs `setup_suspend.sh --refresh` on every boot and rewrites the
drop-ins when the answer changes. (It runs the script from this checkout as
root, so it refuses to install itself if any directory on the path to it is
group- or world-writable.)

One thing the report can't settle for you: `suspend-then-hibernate` arms an
RTC wake alarm to wake the machine and write the image, and some firmware
accepts that alarm and never fires it out of s2idle. The script now checks
that `/sys/class/rtc/rtc*/wakealarm` exists and is writable and says so, but
only a real test proves the rest — `sudo systemctl suspend-then-hibernate`,
wake it, and look for `Hibernating` in `journalctl -b -1`.

Writing a hibernation image and resuming from one are separate problems,
and `CanHibernate` only answers the first — so the report calls out the
resume route separately (`resume=` plus an initramfs hook, or systemd 255+
on EFI, where `/sys/power/resume` reads `0:0` and resume still works). When
it can't find one, it still enables `suspend-then-hibernate` — on
s2idle-only firmware a bounded drain is the whole point, and a cold boot
beats a flat battery — but says so, and one manual `sudo systemctl
hibernate` settles it.

If the firmware offers `deep` (S3) but doesn't use it, the script offers to
switch — usually the single biggest win. It goes in as
`/etc/tmpfiles.d/hykr-mem-sleep.conf`, so a machine whose S3 resume turns
out to be buggy is fixed with one `rm` from a TTY rather than a bootloader
edit.

Measure it rather than trusting it: note
`/sys/class/power_supply/BAT*/capacity`, close the lid for a few hours, and
compare.

<div align="right">
  <sub><a href="#hykr">🡅 back to top</a></sub>
</div>

<a id="credits"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=THANK YOU!" width="450"/>

---

- [See the full Credits page here](Source/CREDITS.md).

<div align="right">
  <sub><a href="#hykr">🡅 back to top</a></sub>
</div>
