Set volume manually (which allows setting to a value much higher than 100%, beware any sound distortions!)

    pactl set-sink-volume @DEFAULT_SINK@ 150%

> Get current setting
>
>     pactl get-sink-volume @DEFAULT_SINK@
