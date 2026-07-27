#!/bin/bash

cmd=$(echo -e "switch\nkill" | fzf --prompt "Action > " --height 10)

if [[ "$cmd" == "switch" ]]; then
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt "Session > ")
  [[ -n "$session" ]] && tmux switch-client -t "$session"
elif [[ "$cmd" == "kill" ]]; then
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --prompt "Kill > ")
  [[ -n "$session" ]] && tmux kill-session -t "$session"
fi
