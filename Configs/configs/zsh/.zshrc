# ~/.zshrc
[[ $- != *i* ]] && return

# Tab completion -- unlike bash (wired up by the bash-completion package's
# own /etc/bash.bashrc hook), zsh needs this called explicitly or completion
# falls back to filename-only.
fpath+=/usr/share/zsh/site-functions
autoload -Uz compinit
compinit

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS SHARE_HISTORY

eval "$(starship init zsh)"
fastfetch

export EDITOR=nvim
export VISUAL=nvim

# fzf: Ctrl+R history search, Ctrl+T file search, Alt+C cd search --
# installing the package alone doesn't wire these, its own shell scripts do
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# zsh-autosuggestions: ghost-text completion from history
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting must be sourced last -- it wraps zle widgets, so
# anything sourced after it (autosuggestions included) can end up unhighlighted
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
