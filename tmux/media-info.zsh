#!/usr/bin/env zsh

# get current playing title of vlc
title=$(qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata | grep "xesam:title:" | cut -c 14-)
state=$(qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlaybackStatus)

if [[ $state == "Playing" ]]
then
    icon=$(echo -e '\u25b6')
elif [[ $state == "Paused" ]]
then
    icon=$(echo -e '\u23f8')
elif [[ $state == "Stopped" ]]
then
    icon=$(echo -e '\u23f9')
else
    icon=""
fi

if [[ -n $title ]]
then
    echo "#[fg=$secondaryFg,bg=$secondaryBg] $icon $title #[default] "
fi
