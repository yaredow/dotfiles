# Fish Shell Configuration
# Migrated from NixOS config

set -g fish_greeting

# Environment PATH
if test -d "$HOME/.local/bin"
    if not contains "$HOME/.local/bin" $PATH
        set -gx PATH "$HOME/.local/bin" $PATH
    end
end

if test -d "$HOME/go/bin"
    if not contains "$HOME/go/bin" $PATH
        set -gx PATH "$HOME/go/bin" $PATH
    end
end

if test -d "$HOME/.bun/bin"
    if not contains "$HOME/.bun/bin" $PATH
        set -gx PATH "$HOME/.bun/bin" $PATH
    end
end

# Shell Aliases
alias ls="eza --color=always"
alias l="eza"
alias ll="eza -lh --git"
alias la="eza -lha --git"
alias tree="eza --tree"

alias gs="git status"
alias gc="git commit"
alias gp="git push"

alias v="nvim"
alias c="clear"
alias ccwd="cd ~/Documents/code"

alias prd="pnpm run dev"
alias prb="pnpm run build"
alias nr="npm run"
alias nrd="npm run dev"
alias brd="bun run dev"

alias oc="opencode"
alias cy="codex --approve-for-me"
alias cx="printf '\\033[2J\\033[3J\\033[H' && claude --permission-mode auto"
alias ytt="youtube-tui"
alias dotfiles="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias ase="nohup emulator -avd Pixel_8 -no-skin > /dev/null 2>&1 &!"

# Custom Functions
function fe --description "Open file with editor"
    set -l files (fd --type f --hidden --follow --exclude .git $argv | \
        fzf -m --preview 'bat --color=always --style=numbers {}' \
            --preview-window=right:60%)
    if test -n "$files"
        echo $files | xargs -d '\n' nvim
    end
end

function fv --description "Find video files and play with mpv"
    set -l files (fd -e mp4 -e mkv -e avi -e webm -e mov -e flv --hidden --follow --exclude .git --exclude Android --exclude node_modules . ~ | \
        fzf -m --query="$argv" --delimiter=/ --with-nth='-1')
    if test (count $files) -gt 0
        nohup mpv --no-terminal $files >/dev/null 2>&1 &
    end
end

function fcd --description "Fuzzy cd into directory"
    set -l dir (fd --type d --hidden --follow --exclude .git $argv | fzf +m)
    if test -n "$dir"
        cd "$dir"
    end
end

function fkill --description "Fuzzy kill process"
    set -l pid (ps -ef | sed 1d | fzf -m | awk '{print $2}')
    if test -n "$pid"
        echo $pid | xargs kill -9
    end
end

function fif --description "Find in files using ripgrep + fzf"
    if test (count $argv) -eq 0
        echo "Usage: fif <pattern>"
        return 1
    end
    set -l match (rg --line-number --no-heading $argv | \
        fzf --delimiter : --preview 'bat --color=always --line-range :500 {1}')
    if test -n "$match"
        set -l file (echo $match | awk -F: '{print $1}')
        set -l line (echo $match | awk -F: '{print $2}')
        nvim "+$line" "$file"
    end
end

function y --description "Yazi wrapper that changes directory on exit"
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# CLI Integrations
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

if command -v atuin >/dev/null 2>&1
    atuin init fish | source
end

if command -v fzf >/dev/null 2>&1
    fzf --fish | source
end

if command -v direnv >/dev/null 2>&1
    direnv hook fish | source
end
