alias ll="eza -lh"
alias la="eza -lha"
alias ls="eza --color=always"
alias l="eza"

alias gs="git status"
alias gc="git commit"
alias gp="git push"

alias v=nvim
alias c=clear
alias ccwd="cd ~/Documents/code"

alias update="sudo pacman -Syu"
alias sp="sudo pacman"

alias prd="pnpm run dev"
alias prb="pnpm run build"
alias nr="npm run"
alias nrd="npm run dev"
alias brd="bun run dev"

alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Yazi wrapper
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
