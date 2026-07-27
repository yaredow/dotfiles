#!/bin/bash

remote=$(git config --get remote.origin.url 2>/dev/null)
if [[ -z "$remote" ]]; then
  notify-send "No GitHub remote found" -t 2000
  exit 1
fi

url=$(echo "$remote" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
xdg-open "$url"
