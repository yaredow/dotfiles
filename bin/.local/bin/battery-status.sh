#!/bin/bash
set -euo pipefail

power_supply_path="${POWER_SUPPLY_PATH:-/sys/class/power_supply}"

battery=$(upower -e 2>/dev/null | grep BAT | head -n 1 || true)
[[ -z $battery ]] && exit 0

battery_info=$(upower -i "$battery")

percentage=$(awk '/percentage/ { print int($2); exit }' <<<"$battery_info")
capacity=$(awk '/energy-full:/ { printf "%d", $2; exit }' <<<"$battery_info")
time_remaining=$(awk '/time to (empty|full)/ {
  value = $4
  unit = $5
  if (unit ~ /^minute/) {
    printf "%dm", int(value)
  } else {
    hours = int(value)
    minutes = int((value - hours) * 60)
    if (minutes > 0) printf "%dh %dm", hours, minutes
    else printf "%dh", hours
  }
  exit
}' <<<"$battery_info")
power_rate_raw=$(awk '/energy-rate/ { print $2; exit }' <<<"$battery_info")
native_path=$(awk '/native-path/ { print $2; exit }' <<<"$battery_info")
battery_path="$power_supply_path/$native_path"

if [[ -r $battery_path/power_now ]]; then
  microwatts=$(<"$battery_path/power_now") || true
  power_rate_raw=$(awk -v microwatts="$microwatts" 'BEGIN { print microwatts / 1000000 }')
elif [[ -r $battery_path/current_now && -r $battery_path/voltage_now ]]; then
  microamps=$(<"$battery_path/current_now") || true
  microvolts=$(<"$battery_path/voltage_now") || true
  power_rate_raw=$(awk -v microamps="$microamps" -v microvolts="$microvolts" 'BEGIN { print microamps * microvolts / 1000000000000 }')
fi

power_rate=$(awk -v rate="${power_rate_raw:-0}" 'BEGIN { rounded = sprintf("%.1f", rate); sub(/\.0$/, "", rounded); print rounded }')
state=$(awk '/state/ { print $2; exit }' <<<"$battery_info")
threshold_start=$(awk '/charge-control-start-threshold:|charge-start-threshold:/ { gsub(/%/, "", $2); print int($2); exit }' <<<"$battery_info")
threshold_end=$(awk '/charge-control-end-threshold:|charge-end-threshold:/ { gsub(/%/, "", $2); print int($2); exit }' <<<"$battery_info")
[[ -z $threshold_end ]] && threshold_end=$(cat "$battery_path"/charge_control_end_threshold 2>/dev/null | head -1 || true)
[[ -z $threshold_start ]] && threshold_start=$(cat "$battery_path"/charge_control_start_threshold 2>/dev/null | head -1 || true)

ac_online=false
for supply in "$power_supply_path"/*; do
  [[ -r $supply/type ]] || continue
  type=$(<"$supply/type") || continue
  [[ "$type" == "Mains" ]] || continue
  [[ -r $supply/online ]] || continue
  online=$(<"$supply/online") || continue
  if [[ "$online" == "1" ]]; then ac_online=true; break; fi
done 2>/dev/null

charge_idle=false
if awk -v rate="${power_rate_raw:-0}" 'BEGIN { exit !(rate <= 0.2) }'; then charge_idle=true; fi

charge_holding=false
if [[ $ac_online == "true" && -n $threshold_end ]]; then
  if [[ $state == "pending-charge" ]]; then charge_holding=true
  elif [[ $state == "fully-charged" ]] && (( percentage < 99 )); then charge_holding=true
  elif [[ $state == "charging" && $charge_idle == "true" ]] && (( threshold_end < 99 && percentage >= threshold_end )); then charge_holding=true
  fi
fi

printf 'percentage\t%s\n' "${percentage}%"
if [[ $charge_holding == "true" ]]; then printf 'state\tholding\n'
else printf 'state\t%s\n' "$state"
fi
printf 'rate\t%s\n' "${power_rate}W"
printf 'size\t%s\n' "${capacity}Wh"
printf 'time\t%s\n' "$time_remaining"

cycles=$(cat "$battery_path"/cycle_count 2>/dev/null | head -1)
[[ -n $cycles ]] && printf 'cycles\t%s\n' "$cycles"

if [[ -n $threshold_end ]]; then
  if [[ -n $threshold_start && $threshold_start != $threshold_end ]]; then
    printf 'threshold\t%s-%s%%\n' "$threshold_start" "$threshold_end"
  else
    printf 'threshold\t%s%%\n' "$threshold_end"
  fi
fi
