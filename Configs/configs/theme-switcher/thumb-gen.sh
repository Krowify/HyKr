#!/usr/bin/env bash
# Generates (and caches) a small thumbnail for theme-picker.sh's rofi icon
# field. Prints the thumbnail's path on success; prints nothing on any
# failure, matching theme-picker.sh's `[[ -n "$thumb" ]]` guard around the
# call -- it just falls back to a plain text entry either way.
set -uo pipefail

src="${1:-}"
[[ -f "$src" ]] || exit 0

if command -v magick &>/dev/null; then
    convert_cmd=(magick)
elif command -v convert &>/dev/null; then
    convert_cmd=(convert)
else
    exit 0
fi

cache_dir="$HOME/.cache/theme-switcher/thumbs"
mkdir -p "$cache_dir"

# Cache key includes mtime so an edited/replaced preview image (e.g. a
# swapped theme wallpaper) regenerates its thumbnail instead of serving a
# stale cached one under the same source path.
src_abs="$(realpath "$src")"
mtime="$(stat -c %Y "$src_abs" 2>/dev/null || echo 0)"
hash="$(printf '%s' "${src_abs}_${mtime}" | md5sum | cut -d' ' -f1)"
out="$cache_dir/$hash.png"

if [[ ! -f "$out" ]]; then
    "${convert_cmd[@]}" "$src_abs" -thumbnail 128x128 -strip -quality 85 "$out" 2>/dev/null || exit 0
fi

[[ -f "$out" ]] && printf '%s' "$out"
