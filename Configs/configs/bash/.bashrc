# ~/.bashrc
[[ $- != *i* ]] && return

eval "$(starship init bash)"
fastfetch

export EDITOR=nvim
export VISUAL=nvim

# fzf: Ctrl+R history search, Ctrl+T file search, Alt+C cd search --
# installing the package alone doesn't wire these, its own shell scripts do
[[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
[[ -f /usr/share/fzf/completion.bash ]] && source /usr/share/fzf/completion.bash
