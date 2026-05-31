#!/usr/bin/env zsh

# Read the active MPRIS player via playerctl (Linux-only).
# playerctl auto-selects the most recently active player, so this surfaces any
# MPRIS-capable app (VLC, mpv via mpv-mpris, Spotify, browsers, …) — not just VLC.
# Install with: sudo pacman -S playerctl
if ! command -v playerctl &>/dev/null; then
    exit
fi

# Both calls print "No players found" to stderr and exit non-zero when nothing
# is playing; 2>/dev/null leaves the vars empty and the wrapper bails on an
# empty title.
state=$(playerctl status 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

echo "$state"
echo "$title"
