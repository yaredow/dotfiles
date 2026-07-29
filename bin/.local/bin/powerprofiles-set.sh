#!/bin/bash
set -euo pipefail

if (($# != 1)); then echo "Usage: powerprofiles-set.sh <profile>" >&2; exit 1; fi

profile_path="/sys/firmware/acpi/platform_profile"

if [[ -w $profile_path ]]; then
  echo "$1" > "$profile_path"
elif command -v powerprofilesctl &>/dev/null; then
  powerprofilesctl set "$1"
else
  echo "No power profile control available" >&2
  exit 1
fi
