#!/bin/bash

if [[ $# -eq 1 ]]; then
  selected=$1
else
  paths=(
    "$HOME/Documents/code"
    "$HOME/Documents"
    "$HOME/go/src"
    "$HOME/.config"
  )
  selected=$(find "${paths[@]}" -maxdepth 3 -name ".git" -type d 2>/dev/null | sed 's|/.git$||' | sort -u | fzf)
fi

[[ -z "$selected" ]] && exit 0

selected_name=$(basename "$selected" | tr . _)

if [[ -z "$TMUX" ]]; then
  tmux new-session -s "$selected_name" -c "$selected" -d 2>/dev/null
  tmux attach-session -t "$selected_name"
else
  tmux new-session -s "$selected_name" -c "$selected" -d 2>/dev/null
  tmux switch-client -t "$selected_name"
fi
