# Scripts

Conventions (following [HyDE](https://github.com/HyDE-Project/HyDE/tree/master/Scripts)'s script layout):

- Every script computes its own dir and sources the shared lib first:
  ```bash
  scrDir="$(dirname "$(realpath "$0")")"
  source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }
  ```
- [`global_fn.sh`](global_fn.sh) is the shared lib — common vars (`repoDir`, `dotsDir`, `confDir`) and helper functions (`print_log`, `link_dot`, …) live there, not duplicated per script.
- Naming: `snake_case`, verb first (`link_dots.sh`), `.sh` for scripts. A script's data file (if any) shares its base name with a different extension (e.g. `dots/waybar.toml`).
- Folders are topics, not install-order stages — no numeric prefixes. [`dots/`](dots) holds per-app manifests, [`extra/`](extra) holds optional/secondary scripts.
- [`pkg_core.lst`](pkg_core.lst) — packages needed to actually run what's in `Configs/` (one per line, `#` comment explaining why). [`pkg_extra.lst`](pkg_extra.lst) — optional apps (not required by anything in `Configs/`). Following HyDE's `pkg_*.lst` naming; no install script consumes either yet. Package names/commands cross-checked against elifouts/Dotfiles' `InstallScripts/` (`yay -S --needed ...`).
