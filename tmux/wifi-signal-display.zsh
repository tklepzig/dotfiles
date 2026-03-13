#!/usr/bin/env zsh

cache_file="/tmp/tmux_wifi_signal_cache"
cache_ttl=3

# Refresh cache in background if missing or stale
if [[ ! -f "$cache_file" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0) )) -ge $cache_ttl ]]; then
    ($HOME/.dotfiles/tmux/wifi-signal.$1.zsh 2>/dev/null > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file" &)
fi

# Return empty if no cache yet
if [[ ! -f "$cache_file" ]]; then
    echo ""
    exit
fi

{
    read -r state
    read -r value
} < "$cache_file"

if [[ -z "$state" ]]; then
    echo ""
    exit
fi

if [[ "$state" = "disconnected" ]]; then
    echo "#[fg=$infoFg,bg=$infoBg] ⊘"
    exit
fi

if [[ "$state" = "excellent" ]]; then
    bars="▂▄▆█"
    color="#[fg=$secondaryFg,bg=$secondaryBg]"
elif [[ "$state" = "good" ]]; then
    bars="▂▄▆"
    color="#[fg=$secondaryFg,bg=$secondaryBg]"
elif [[ "$state" = "fair" ]]; then
    bars="▂▄"
    color="#[fg=$warningFg,bg=$warningBg]"
else
    bars="▂"
    color="#[fg=$criticalFg,bg=$criticalBg]"
fi

echo "$color $bars"
