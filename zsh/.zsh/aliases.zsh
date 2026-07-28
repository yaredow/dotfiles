# ==============================
# File listing (eza — modern ls)
# ==============================
alias ls="eza --color=always"
alias l="eza"                              # short list
alias ll="eza -lh --git"                   # long list with git status
alias la="eza -lha --git"                  # long list, all files + git
alias tree="eza --tree"                    # tree view (replaces `tree` command)

# ==============================
# Package management
# ==============================
alias sp="sudo pacman"
alias sps="sudo pacman -S"
alias spu="sudo pacman -Syu"

# ==============================
# Git
# ==============================
alias gs="git status"
alias gc="git commit"
alias gp="git push"

# ==============================
# Editors & navigation
# ==============================
alias v=nvim
alias c=clear
alias ccwd="cd ~/Documents/code"

# ==============================
# Development
# ==============================
alias prd="pnpm run dev"
alias prb="pnpm run build"
alias nr="npm run"
alias nrd="npm run dev"
alias brd="bun run dev"

# ==============================
# Tmux
# ==============================
alias mux='pgrep -vx tmux > /dev/null && \
  tmux new -d -s delete-me && \
  tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh && \
  tmux kill-session -t delete-me && \
  tmux attach || tmux attach'

# ==============================
# fzf
# ==============================

# fe - open file with $EDITOR
fe() {
  local files
  files=$(fd --type f --hidden --follow --exclude .git "$@" |
    fzf -m --preview 'bat --color=always --style=numbers {}' \
      --preview-window=right:60%)
  [[ -n "$files" ]] && echo "$files" | xargs -d '\n' ${EDITOR:-nvim}
}

# fv - find video files and play with mpv (detached)
fv() {
  local files
  files=$(fd -e mp4 -e mkv -e avi -e webm -e mov -e flv --hidden --follow --exclude .git --exclude Android --exclude node_modules . ~ |
    fzf -m --query="${(j: :)@}" --delimiter=/ --with-nth='-1' --preview 'ffprobe -hide_banner {} 2>&1 | head -20')
  if [[ -n "$files" ]]; then
    nohup mpv --no-terminal ${(f)files} >/dev/null 2>&1 &
    exec true
  fi
}

# fcd - cd into selected directory
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git "$@" | fzf +m)
  [[ -n "$dir" ]] && cd "$dir"
}

# fkill - kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

# fif - find in files using ripgrep + fzf
fif() {
  if [[ ! "$#" -gt 0 ]]; then echo "Usage: fif <pattern>"; return 1; fi
  rg --line-number --no-heading "$@" |
    fzf --delimiter : --preview 'bat --color=always --line-range :500 {1}' |
    awk -F: '{print $1}' | xargs -r ${EDITOR:-nvim}
}

# ==============================
# Other
# ==============================
alias oc="opencode"
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ase='nohup emulator -avd Pixel_8 > /dev/null 2>&1 &!'

# ==============================
# Yazi wrapper
# ==============================
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
