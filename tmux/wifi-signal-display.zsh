#!/usr/bin/env zsh

cache_file="/tmp/tmux_wifi_signal_cache"
cache_ttl=3
# A probe exiting non-zero leaves the cache untouched, so bound how long its
# last value is trusted — otherwise a permanently broken probe shows bars forever.
cache_max_age=30

cache_age=-1
if [[ -f "$cache_file" ]]; then
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
    cache_age=$(( $(date +%s) - cache_mtime ))
fi

# Refresh cache in background if missing or stale
if (( cache_age < 0 || cache_age >= cache_ttl )); then
    ($HOME/.dotfiles/tmux/wifi-signal.$1.zsh 2>/dev/null > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file" &)
fi

# Return empty if no cache yet
if (( cache_age < 0 )); then
    echo ""
    exit
fi

{
    read -r state
    read -r value
} < "$cache_file"

(( cache_age >= cache_max_age )) && state="disconnected"

if [[ -z "$state" ]]; then
    echo ""
    exit
fi

if [[ "$state" = "disconnected" ]]; then
    echo "#[fg=$statusInactiveFg] ✕"
    exit
fi

if [[ "$state" = "excellent" ]]; then
    bars="▂▄▆█"
    # Alternative
    #bars="▪▪▪▪"
    color="#[fg=$secondaryText]"
elif [[ "$state" = "good" ]]; then
    bars="▂▄▆"
    #bars="▪▪▪▫"
    color="#[fg=$secondaryText]"
elif [[ "$state" = "fair" ]]; then
    bars="▂▄"
    #bars="▪▪▫▫"
    color="#[fg=$warningBg]"
else
    bars="▂"
    #bars="▪▫▫▫"
    color="#[fg=$criticalBg]"
fi

echo "$color $bars"
