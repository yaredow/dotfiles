# ==============================
# Antidote (plugin manager)
# ==============================
source /usr/share/zsh-antidote/antidote.zsh
antidote load

# ==============================
# Starship prompt
# ==============================
eval "$(starship init zsh)"


# ==============================
# fzf
# ==============================
source <(fzf --zsh)

# ==============================
# History
# ==============================
HISTFILE=~/.zsh_history
HISTSIZE=15000
SAVEHIST=15000

setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt AUTOCD

# ==============================
# Completion
# ==============================
autoload -Uz compinit
compinit -C

# ==============================
# Keybindings
# ==============================
bindkey -v  # vi mode for command-line editing (Esc to enter normal mode)
bindkey '^f' autosuggest-accept        # Ctrl+f to accept autosuggestion
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^r' history-incremental-search-backward

# ==============================
# Load modular dotfiles
# ==============================
for file in ~/.zsh/*.zsh; do
  [[ -f "$file" ]] && source "$file"
done

# ==============================
# atuin (shell history)
# ==============================
eval "$(atuin init zsh)"

# ==============================
# zoxide
# ==============================
eval "$(zoxide init zsh)"

# ==============================
# pnpm
# ==============================
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# ==============================
# Go
# ==============================
export PATH="$PATH:$HOME/go/bin"

# ==============================
# bun completions
# ==============================
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

eval "$(direnv hook zsh)"
export PATH="$HOME/.local/bin:$PATH"
