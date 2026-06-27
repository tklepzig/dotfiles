#!/usr/bin/env zsh
#
# CPU package temperature. Emits `state\nvalue` (e.g. "normal\n56").
# Scans thermal zones for x86_pkg_temp by type — the zone *index* isn't stable
# across reboots, so /sys/class/thermal/thermal_zone9 can't be hardcoded.

temp_file=''
for zone in /sys/class/thermal/thermal_zone*; do
    if [[ "$(<$zone/type)" == "x86_pkg_temp" ]]; then
        temp_file="$zone/temp"
        break
    fi
done

# Fallback: acpitz (motherboard sensor) if no package sensor exists.
if [[ -z "$temp_file" ]]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        if [[ "$(<$zone/type)" == "acpitz" ]]; then
            temp_file="$zone/temp"
            break
        fi
    done
fi

[[ -z "$temp_file" || ! -r "$temp_file" ]] && exit

celsius=$(( $(<"$temp_file") / 1000 ))   # millidegrees → °C

if   (( celsius >= 90 )); then state=critical   # nearing the 100°C throttle
elif (( celsius >= 80 )); then state=warning
else                           state=normal
fi

echo "$state"
echo "$celsius"
