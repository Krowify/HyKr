# ~/.bashrc
[[ $- != *i* ]] && return

eval "$(starship init bash)"
fastfetch

export EDITOR=nvim
export VISUAL=nvim
