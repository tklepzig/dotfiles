# ffmpeg

## Extract frames

Use the `ffmpeg-extract-frames` script for common cases:

```
ffmpeg-extract-frames video.mkv frames/ --fps source --start 00:00:58 --end 00:01:02
ffmpeg-extract-frames video.mkv frames/ --fps 1 --start 00:01:14 --end 00:01:19
ffmpeg-extract-frames video.mkv frames/          # whole video, all frames
```

Add `--accurate` when you need a specific frame (inpainting, compositing) —
without it, ffmpeg seeks to the nearest keyframe which can be seconds off. See
the [`-ss` placement](#-ss-placement) table below.

### Raw commands

**Whole video, all frames (source fps):**

```
ffmpeg -i input.mkv -vf fps=source_fps frames/%04d.png
```

**Time range, 1 fps (fast/approximate seek):**

```
ffmpeg -ss 00:00:58 -to 00:01:02 -i input.mkv -vf fps=1 frames/%04d.png
```

**Time range, all frames (fast seek):**

```
ffmpeg -ss 00:00:58 -to 00:01:02 -i input.mkv -vf fps=source_fps frames/%04d.png
```

**Time range, all frames (frame-accurate seek — slow):**

```
ffmpeg -i input.mkv -ss 00:00:58 -to 00:01:02 -vf fps=source_fps frames/%04d.png
```

### `-ss` placement

| Position    | Speed                            | Accuracy       |
| ----------- | -------------------------------- | -------------- |
| Before `-i` | Fast (seeks to nearest keyframe) | ±seconds off   |
| After `-i`  | Slow (decodes from start)        | Frame-accurate |

For inpainting / compositing work where exact frames matter, use after `-i` (or
`--accurate` in the script).

**`-to` is interpreted differently depending on `-ss` placement:**

- `-ss` before `-i`: `-to` is relative to the _input_ (absolute timestamp in the
  file)
- `-ss` after `-i`: `-to` is relative to the _output_ (i.e. relative to `-ss`)

If a range comes out wrong or too short, this is the first thing to check.
