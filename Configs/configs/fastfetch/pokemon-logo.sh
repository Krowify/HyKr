#!/usr/bin/env bash
# Random Pokémon sprite as fastfetch's logo, via pokeget.
#
# config.jsonc points at this with "type": "command-raw", which runs the
# command and uses its stdout as the logo -- so EVERY fastfetch invocation
# gets a new Pokémon, not just the one your shell rc fires at login. That is
# also why this isn't the upstream approach (github.com/Discomanfulanito/
# pokefetch), which wraps the fetcher in a shell function: that only covers
# interactive shells, and it runs the whole fetch a SECOND time just to
# measure its height for centring. Normalising the sprite into a fixed box
# here gets the same placement without ever invoking fastfetch recursively.
#
# Sprite names come from pokeget; entries may carry its flags (-s for shiny,
# --mega-y and friends for alternate forms). `pokeget --help` lists them.
POKEMON_LIST=(
  victini
  "mimikyu -s"
  celebi
  furret
  "mewtwo --mega-y"
)

WIDTH=38          # logo box width, in columns
HEIGHT=16         # logo box height; roughly the module count in config.jsonc
FALLBACK="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/jirachi.txt"

# Any failure falls back to the static logo rather than leaving fastfetch with
# an empty logo column -- a missing pokeget shouldn't make the whole fetch look
# broken.
fallback() {
  # The two leading blank lines stand in for the "top": 2 the logo block used
  # to carry: vertical placement moved into this script, so config.jsonc now
  # sets "top": 0 and the fallback has to supply its own.
  [[ -f "$FALLBACK" ]] && { printf '\n\n'; cat "$FALLBACK"; }
  exit 0
}

command -v pokeget >/dev/null 2>&1 || fallback

sprite=$(pokeget ${POKEMON_LIST[RANDOM % ${#POKEMON_LIST[@]}]} --hide-name 2>/dev/null) || fallback
[[ -n "$sprite" ]] || fallback

# True printed width: strip SGR escapes first, or every colour code counts
# toward the column total and the sprite ends up jammed against the left edge.
sprite_w=$(printf '%s\n' "$sprite" \
  | sed 's/\x1b\[[0-9;]*m//g' \
  | awk '{ if (length > m) m = length } END { print m+0 }')
sprite_h=$(printf '%s\n' "$sprite" | wc -l)

pad_left=$(( (WIDTH - sprite_w) / 2 ))
(( pad_left < 0 )) && pad_left=0
indent=$(printf '%*s' "$pad_left" '')

# Vertical centring within a fixed box, so a tall Mewtwo and a short Furret
# both sit in the same place instead of the module list appearing to shift
# between runs. A sprite taller than the box is simply never padded.
pad_top=$(( (HEIGHT - sprite_h) / 2 ))
(( pad_top < 0 )) && pad_top=0

for (( i = 0; i < pad_top; i++ )); do echo; done
printf '%s\n' "$sprite" | sed "s/^/${indent}/"
