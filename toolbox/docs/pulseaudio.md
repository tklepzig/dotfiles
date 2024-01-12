# PulseAudio

List pulse sinks (and getting the number for the commands below)

    pactl list short sinks

Set volume

    pactl set-sink-volume <sink-number> 85%

Get volume

    pactl get-sink-volume <sink-number>

> Alternatively run
>
>     alsamixer

## Usage with VLC

Specify pulse sink when running cvlc by number from above's output with specific
volume

    PULSE_SINK=71 cvlc -A pulse --gain [0-8] (eher 1-2) Adiemus.mp3
