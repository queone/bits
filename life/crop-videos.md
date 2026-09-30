---
type: howto
---
## Cropping Videos

Crop the sides of a widescreen clip (16:9) down to the old 4:3 movie shape with [FFmpeg](https://en.wikipedia.org/wiki/FFmpeg):

```bash
ffmpeg -i input.mp4 -vf "crop=ih*4/3:ih:(iw-ih*4/3)/2:0" -t 5 -c:a copy output.mp4
```

- `-i input.mp4`: the input video file.
- `-vf "crop=ih*4/3:ih:(iw-ih*4/3)/2:0"`: the crop filter.
  - `ih` is the input height.
  - `ih*4/3` is the new width that keeps a 4:3 aspect ratio.
  - `(iw-ih*4/3)/2` centers the crop horizontally.
- `-t 5`: optional; keeps only the first 5 seconds.
- `-c:a copy`: copies the audio stream without re-encoding.
- `output.mp4`: the output file.

To put a song under the clip instead, see [Mix Music Into a Video](mix-music-video.md).
