# Set Volume
## Specify dB
amixer set PCM -- -XYY
Which will set the volume to -X.YYdB
## Specify percentage (set to max)
set volume: amixer set PCM -- 100%
force audio to 3.5mm jack: via raspi-config (advanced options)

set audio output via commandline:

amixer cset numid=3 n
where n is 0=auto, 1=headphones, 2=hdmi

get current output
amixer cget numid=3

### Get rid of white noise

In /boot/config.txt add the following line:
`audio_pwm_mode=2`
