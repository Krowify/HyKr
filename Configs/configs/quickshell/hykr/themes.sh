#!/usr/bin/env bash
# One line per installed theme for the desktop shell's theme picker:
#
#   <id>\t<name>\t<preview image>\t<dynamic: true|false>\t<active: true|false>
#
# Preview: the theme's preview.png, else its default_wallpaper, else the first
# image in its folder -- the same order theme-picker.sh used. "dynamic" is
# theme.json's dynamic_colors: those themes take their colours from a
# wallpaper, so the picker asks for one. "active" marks the theme in
# current-theme.json (old ids from before a rename count as their new one).
set -uo pipefail

BASE="$HOME/.config/theme-switcher"
current="$(jq -r '.theme // empty' "$BASE/current-theme.json" 2>/dev/null || true)"
case "$current" in blackturq) current=default ;; catppuccin) current=arch ;; laptop) current=sakura ;; esac

for dir in "$BASE"/themes/*/; do
  dir="${dir%/}"
  json="$dir/theme.json"
  [[ -r "$json" ]] || continue
  id="$(basename "$dir")"
  IFS=$'\t' read -r name wp dynamic < <(jq -r --arg id "$id" \
    '[(.name // $id), (.default_wallpaper // ""), ((.dynamic_colors // false) | tostring)] | @tsv' "$json" 2>/dev/null) || continue

  preview=""
  if [[ -f "$dir/preview.png" ]]; then
    preview="$dir/preview.png"
  elif [[ -n "$wp" && -f "$dir/$wp" ]]; then
    preview="$dir/$wp"
  else
    preview="$(find -L "$dir" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | LC_ALL=C sort | head -n1)"
  fi

  active=false
  [[ "$id" == "$current" ]] && active=true
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$name" "$preview" "$dynamic" "$active"
done | LC_ALL=C sort -f -t $'\t' -k2,2
