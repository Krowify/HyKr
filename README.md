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
│   ├── extra/                # optional/secondary scripts (install_sddm_theme.sh, setup_firewall.sh)
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
> drop-in. It then **asks** before each of: the Hyprland gesture plugins,
> disabling `sshd`, and `usbguard`.
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

<a id="credits"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=THANK YOU!" width="450"/>

---

- [See the full Credits page here](Source/CREDITS.md).

<div align="right">
  <sub><a href="#hykr">🡅 back to top</a></sub>
</div>
