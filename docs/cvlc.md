quit playback after the playlist is played fully:
```
cvlc audio1.mp3 audio2.mp3 vlc://quit
```

Send commands to running `cvlc` process:
```
dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
```

Or, with `qdbus` installed:
```
qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
```

The last `PlayPause` can be replaced with, e.g., `Play`, `Pause`, `Previous`, `Next`.

Example how to quit cvlc process:
```
dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Quit
```
```
qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Quit
```

All available commands: https://specifications.freedesktop.org/mpris-spec/latest/index.html
