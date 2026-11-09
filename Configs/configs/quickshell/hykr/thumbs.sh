#!/usr/bin/env bash
# Thumbnails for the desktop shell's wallpaper and theme pickers.
#
#   thumbs.sh <cache-dir> <file>...     (or file paths on stdin, one per line)
#
# Prints one line per image, "<path>\t<thumbnail>", as soon as that image's
# thumbnail is ready -- cached ones first and at once, new ones as they are
# generated, a few at a time. The thumbnail is named after the md5 of the
# image's path, the same Qt.md5(path) the QML uses, so the cache survives
# restarts. A thumbnail older than its image is regenerated.
#
# Without ImageMagick the thumbnail field is empty and the picker falls back
# to loading the image itself at a reduced size.
set -uo pipefail

cache="${1:?usage: thumbs.sh <cache-dir> <file>...}"
shift
mkdir -p "$cache"

if command -v magick >/dev/null 2>&1; then
  convert_cmd=(magick)
elif command -v convert >/dev/null 2>&1; then
  convert_cmd=(convert)
else
  convert_cmd=()
fi

files() {
  if [[ $# -gt 0 ]]; then printf '%s\n' "$@"; else cat; fi
}

todo=()
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  if [[ ${#convert_cmd[@]} -eq 0 ]]; then
    printf '%s\t\n' "$f"
    continue
  fi
  thumb="$cache/$(printf '%s' "$f" | md5sum | cut -d' ' -f1).jpg"
  if [[ -s "$thumb" && "$thumb" -nt "$f" ]]; then
    printf '%s\t%s\n' "$f" "$thumb"
  else
    todo+=("$f")
  fi
done < <(files "$@")

for f in "${todo[@]}"; do
  thumb="$cache/$(printf '%s' "$f" | md5sum | cut -d' ' -f1).jpg"
  (
    # [0]: first frame only, so a GIF makes one thumbnail, not one per frame.
    if "${convert_cmd[@]}" "${f}[0]" -thumbnail '480x270^' -gravity center -extent 480x270 \
         -strip -quality 82 "$thumb" 2>/dev/null; then
      printf '%s\t%s\n' "$f" "$thumb"
    else
      printf '%s\t\n' "$f"
    fi
  ) &
  while (( $(jobs -rp | wc -l) >= 4 )); do
    wait -n
  done
done
wait
