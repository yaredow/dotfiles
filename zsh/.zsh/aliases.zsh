alias ll="eza -lh"
alias la="eza -lha"
alias ls="eza --color=always"
alias l="eza"

alias sps="sudo pacman -S"
alias spu="sudo pacman -Syu"

alias gs="git status"
alias gc="git commit"
alias gp="git push"

alias v=nvim
alias c=clear
alias ccwd="cd ~/Documents/code"

alias oc="opencode"

alias update="sudo pacman -Syu"
alias sp="sudo pacman"

alias prd="pnpm run dev"
alias prb="pnpm run build"
alias nr="npm run"
alias nrd="npm run dev"
alias brd="bun run dev"
alias mux='pgrep -vx tmux > /dev/null && \
        tmux new -d -s delete-me && \
        tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh && \
        tmux kill-session -t delete-me && \
        tmux attach || tmux attach'

# youtube fzf
ytplay() {
  ytfzf -t -p mpv "$*"
}

alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Android studio
alias ase='nohup emulator -avd Pixel_8 > /dev/null 2>&1 &!'

# Yazi wrapper
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
