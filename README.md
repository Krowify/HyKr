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
│   │               #   theme-switcher) + bash/.bashrc → ~/.bashrc
│   ├── .local/    # dotfiles → ~/.local
│   └── sddm/      # SDDM themes → /usr/share/sddm/themes (pixel-sakura)
├── Scripts/
│   ├── install.sh            # single entrypoint: root handoff -> GPU drivers -> packages ->
│   │                          #   link_dots -> enable_services -> SDDM/firewall (optional)
│   ├── install_gpu_drivers.sh # auto-detects the GPU (lspci), installs mesa and/or nvidia-open
│   ├── enable_services.sh    # enables sddm/NetworkManager/bluetooth — not optional
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
sudo pacman -Syu --needed git base-devel
git clone --depth 1 https://github.com/krowify/HyKr ~/HyKr
cd ~/HyKr/Scripts
./install.sh
```

> [!IMPORTANT]
> Run as root right after `pacstrap` (fresh install, no user yet)? `install.sh`
> prompts for a username, creates it if needed, and re-execs the rest of
> itself as that user — everything past that point runs as a regular user
> with `sudo`, not as root.
>
> `install.sh` auto-detects your GPU and installs the matching driver,
> installs `yay` if missing, installs everything in `pkg_core.lst`,
> optionally `pkg_extra.lst`, links the dotfiles, enables `sddm`/
> `NetworkManager`/`bluetooth` (not optional — skipping these means no
> login screen, no network, no bluetooth after reboot), then asks before
> installing the SDDM theme and running the security hardening step
> (firewalld + sysctl anti-spoofing + fail2ban). Firewalld denies all
> incoming by default on any untrusted network — if you SSH into this
> machine or use LAN file sharing, re-add what you need afterward:
> `sudo firewall-cmd --zone=public --add-service=ssh --permanent && sudo firewall-cmd --reload`

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
