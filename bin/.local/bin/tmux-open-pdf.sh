#!/bin/bash

selected=$(fd -e pdf --hidden --max-depth 6 "$HOME" 2>/dev/null | fzf)
[[ -n "$selected" ]] && nohup zathura "$selected" >/dev/null 2>&1 &
