#!/usr/bin/env bash
# Symlinks every app manifest in Scripts/dots/*.toml from Configs/ into $HOME.

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/global_fn.sh" || { echo "Error: unable to source global_fn.sh"; exit 1; }

for manifest in "${dotsDir}"/*.toml; do
    source_rel="$(grep '^source' "$manifest" | cut -d'"' -f2)"
    target_rel="$(grep '^target' "$manifest" | cut -d'"' -f2)"

    src="${repoDir}/${source_rel}"
    dst="${target_rel/#\~/$HOME}"

    link_dot "$src" "$dst"
done
