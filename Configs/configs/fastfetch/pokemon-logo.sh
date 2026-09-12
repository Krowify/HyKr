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
# pokeget embeds sprites for the WHOLE Pokedex in its own binary -- nothing is
# downloaded and there is no sprite pack to install -- so "more variety" is a
# config question, not a fetching one.
#
# Empty list (the default) means pokeget's own `random`, drawing from every
# Pokemon it ships. Fill the list instead to restrict the pool to favourites;
# entries may carry pokeget's flags (-s shiny, --mega-y and other alternate
# forms, --alolan). `pokeget --help` lists them.
POKEMON_LIST=()
# POKEMON_LIST=(victini "mimikyu -s" celebi furret "mewtwo --mega-y")

# Percent chance of rolling a shiny when drawing at random -- the real games
# use ~1/4096, which you would never actually see. 0 disables it. Ignored when
# POKEMON_LIST is non-empty, since entries there carry their own flags.
SHINY_CHANCE=10

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

if (( ${#POKEMON_LIST[@]} > 0 )); then
  pick=${POKEMON_LIST[RANDOM % ${#POKEMON_LIST[@]}]}
else
  pick=random
  (( SHINY_CHANCE > 0 && RANDOM % 100 < SHINY_CHANCE )) && pick="random -s"
fi

sprite=$(pokeget $pick --hide-name 2>/dev/null) || fallback
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
