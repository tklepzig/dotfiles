#!/usr/bin/env zsh

# Read the macOS "Now Playing" info via nowplaying-cli.
# Install with: brew install nowplaying-cli
if ! command -v nowplaying-cli &>/dev/null; then
    exit
fi

title=$(nowplaying-cli get title 2>/dev/null)

# nowplaying-cli emits "null" when nothing is playing.
if [[ -z $title || $title == "null" ]]; then
    exit
fi

playbackRate=$(nowplaying-cli get playbackRate 2>/dev/null)
bundleId=$(nowplaying-cli get clientBundleIdentifier 2>/dev/null)

if [[ $playbackRate == 1* ]]; then
    # VLC has a MediaRemote bug: it reports playbackRate=1 both when playing
    # and when paused, so paused VLC will incorrectly show the play icon.
    state="Playing"
elif [[ -n $playbackRate && $playbackRate != "null" ]]; then
    # playbackRate is present but not ≥1 (i.e. "0").
    # Standard players use 0 for paused; VLC uses 0 for stopped (keeps the
    # NowPlaying entry with title intact even after pressing Stop).
    if [[ $bundleId == "org.videolan.vlc" ]]; then
        state="Stopped"
    else
        state="Paused"
    fi
else
    state="Stopped"
fi

echo "$state"
echo "$title"
