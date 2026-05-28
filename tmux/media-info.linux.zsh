#!/usr/bin/env zsh

# Read VLC's MPRIS DBus interface (Linux-only).
title=$(qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata 2>/dev/null | grep "xesam:title:" | cut -c 14-)
state=$(qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus 2>/dev/null)

echo "$state"
echo "$title"
