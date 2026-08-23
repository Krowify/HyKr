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
│   ├── configs/   # dotfiles → ~/.config
│   └── .local/    # dotfiles → ~/.local
├── Scripts/
│   ├── dots/      # install/linking scripts
│   └── extra/     # optional/supporting scripts
└── Source/
    ├── wallpapers/  # shipped wallpapers
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
> This repo is in its scaffolding stage — `Scripts/dots/` doesn't have an
> install script yet. Once one exists, install will look like:

```shell
sudo pacman -S --needed git base-devel
git clone --depth 1 https://github.com/krowify/HyKr ~/HyKr
cd ~/HyKr/Scripts/dots
./install.sh
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
