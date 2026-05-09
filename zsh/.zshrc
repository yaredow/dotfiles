source ~/.zshenv

HISTFILE=~/.zsh_history
HISTSIZE=15000
SAVEHIST=15000

setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt autocd

# Completion
autoload -U compinit && compinit

# Key bindings
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^r' history-incremental-search-backward

# Source modular files
for file in ~/.zsh/*.zsh; do
    [ -f "$file" ] && source "$file"
done

# Starship + Zoxide
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"


# pnpm
export PNPM_HOME="/home/yada/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/go/bin
