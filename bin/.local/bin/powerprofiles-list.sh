#!/bin/bash
set -euo pipefail

output=$(powerprofilesctl list 2>/dev/null || true)
if [[ -z $output ]]; then
  # fallback to sysfs
  profile_path="/sys/firmware/acpi/platform_profile"
  choices_path="${profile_path}_choices"
  if [[ ! -r $choices_path ]]; then exit 1; fi
  choices=$(<"$choices_path")
  active=$(cat "$profile_path" 2>/dev/null || echo "")
  for p in $choices; do
    if [[ $p == "$active" ]]; then echo -e "$p\t1"
    else echo -e "$p\t0"
    fi
  done
  exit 0
fi

current=$(echo "$output" | awk '/^\*/ { gsub(/:/, "", $2); print $2; exit }')

echo "$output" | awk -v cur="$current" '
/^  [a-z]/ {
  gsub(/:/, "", $1)
  if ($1 == cur) print $1 "\t1"
  else print $1 "\t0"
}
/^\* [a-z]/ {
  gsub(/:/, "", $2)
  if ($2 == cur) print $2 "\t1"
  else print $2 "\t0"
}
' || true
