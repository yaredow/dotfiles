# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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

# Powerlevel10k
source ~/.local/share/zsh/powerlevel10k/powerlevel10k.zsh-theme

# Zoxide
eval "$(zoxide init zsh)"


# pnpm
export PNPM_HOME="/home/yada/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/go/bin

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
