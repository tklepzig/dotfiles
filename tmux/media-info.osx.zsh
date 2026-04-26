#!/usr/bin/env zsh

# Read the macOS "Now Playing" info via nowplaying-cli.
# Install with: brew install nowplaying-cli
if ! command -v nowplaying-cli &>/dev/null; then
    exit
fi

title=$(nowplaying-cli get title 2>/dev/null)
playbackRate=$(nowplaying-cli get playbackRate 2>/dev/null)

# nowplaying-cli emits "null" when nothing is playing.
if [[ -z $title || $title == "null" ]]; then
    exit
fi

if [[ $playbackRate == 1* ]]; then
    state="Playing"
elif [[ -n $playbackRate ]]; then
    state="Paused"
else
    state="Stopped"
fi

echo "$state"
echo "$title"
