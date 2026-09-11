#!/usr/bin/env bash
# ImageMagick 7 dropped the `convert` compatibility shim, so a hardcoded
# `convert` silently produced zero thumbnails on a current Arch box. Resolve
# the binary the same way theme-switcher/thumb-gen.sh does -- prefer
# `magick`, fall back to `convert` for an ImageMagick 6 holdout, and say so
# rather than looping in silence if neither is present (imagemagick lives in
# pkg_extra.lst, so it genuinely may not be installed).
if command -v magick >/dev/null 2>&1; then
    convert_cmd=(magick)
elif command -v convert >/dev/null 2>&1; then
    convert_cmd=(convert)
else
    echo "cache.sh: neither 'magick' nor 'convert' found — install imagemagick for wallpaper thumbnails" >&2
    exit 0
fi

CONFIG="$1/config.json"



wallpaper_path=$(jq -r '.wallpaper_path' "$CONFIG")
cache_path=$(jq -r '.cache_path' "$CONFIG")
cache_batch_size=$(jq -r '.cache_batch_size' "$CONFIG")

mkdir -p "$cache_path"

echo "Wallpaper path: $wallpaper_path"
echo "Cache path: $cache_path"

# ! -name pywallpaper.jpg: see shell.qml's own find -- it is a copy of the
# last-picked wallpaper, not a wallpaper of its own, and thumbnailing it just
# burns a slot on a duplicate.
find "$wallpaper_path" -type f ! -name 'pywallpaper.jpg' \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" \
\) | while read -r img; do

    filename=$(basename "$img")
    out="$cache_path/$filename"

    if [[ -f "$out" ]]; then
        continue
    fi

    echo "Generating thumbnail for $filename"


    "${convert_cmd[@]}" "$img" -thumbnail x500 -strip -quality 85 "$out" &

    # Only limit jobs if batch_size > 0
    if (( cache_batch_size > 0 )); then
        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do
            wait -n
        done
    fi

done

wait

echo "Thumbnail generation complete."
