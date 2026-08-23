<div align="center">

# HyKr

<sub>_A built-from-scratch dotfiles repo for Arch Linux._</sub>

<br>

<a href="#structure"><kbd> <br> Structure <br> </kbd></a>&ensp;&ensp;
<a href="#installation"><kbd> <br> Installation <br> </kbd></a>&ensp;&ensp;
<a href="Source/wallpapers"><kbd> <br> Wallpapers <br> </kbd></a>&ensp;&ensp;
<a href="Source/CREDITS.md"><kbd> <br> Credits <br> </kbd></a>

</div>
<br>

<a id="structure"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=STRUCTURE" width="450"/>

---

```
HyKr/
├── Configs/
│   ├── configs/   # dotfiles → ~/.config (waybar, wofi, swaync, hypr, nvim, starship.toml)
│   ├── .local/    # dotfiles → ~/.local
│   └── sddm/      # SDDM themes → /usr/share/sddm/themes (pixel-sakura)
├── Scripts/
│   ├── global_fn.sh  # shared lib, sourced by every script
│   ├── link_dots.sh  # symlinks Configs/configs/* into $HOME per Scripts/dots manifest
│   ├── dots/         # one .toml manifest per app (source → target)
│   └── extra/        # optional/secondary scripts (e.g. install_sddm_theme.sh)
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

> [!IMPORTANT]
> This repo is still in its scaffolding stage — keybinds haven't been set
> up yet, and there's no full install script. `Scripts/link_dots.sh`
> symlinks the current app configs into place:

```shell
sudo pacman -S --needed git base-devel
git clone --depth 1 https://github.com/krowify/HyKr ~/HyKr
cd ~/HyKr/Scripts
./link_dots.sh
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
