# ==============================
# Oh My Zsh
# ==============================
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ==============================
# Starship prompt
# ==============================
eval "$(starship init zsh)"


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
compinit


# ==============================
# Keybindings
# ==============================
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^r' history-incremental-search-backward


# ==============================
# Load your modular dotfiles
# ==============================

# Load aliases explicitly
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh

# Load any other .zsh modules in ~/.zsh/
for file in ~/.zsh/*.zsh; do
  [[ -f "$file" ]] && source "$file"
done


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

# mimocode
export PATH=/home/yada/.mimocode/bin:$PATH
