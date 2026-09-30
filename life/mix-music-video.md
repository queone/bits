---
type: howto
---
## Mix Music Into a Video

Put a song under a clip's own sound with [FFmpeg](https://en.wikipedia.org/wiki/FFmpeg), so the room noise stays and the music plays over it. Start with the song as an audio file. If the song is inside a video, pull the audio out first.

### 1. Extract the song

```bash
ffmpeg -i song.mp4 -vn -c:a copy song.m4a
```

- `-vn`: drops the video stream.
- `-c:a copy`: copies the audio without re-encoding.

### 2. Trim the start of the song

```bash
ffmpeg -ss 15 -i song.m4a -c copy song-cut.m4a
```

- `-ss 15`: starts 15 seconds in. Placed before `-i`, it seeks the input, so the cut is fast.
- `-c copy`: copies the stream without re-encoding.

Repeat with a different offset until the song starts where the clip needs it.

### 3. Mix the song under the clip

```bash
ffmpeg -i clip.mp4 -i song-cut.m4a \
  -filter_complex "[0:a]volume=0.5[v];[1:a]volume=2.0[m];[v][m]amix=inputs=2:duration=first" \
  -c:v copy mixed.mp4
```

- `[0:a]volume=0.5[v]`: the clip's own audio at half volume, labeled `v`.
- `[1:a]volume=2.0[m]`: the song at double volume, labeled `m`.
- `amix=inputs=2:duration=first`: mixes the two and stops when the first input, the clip, ends.
- `-c:v copy`: keeps the video stream untouched, so only the audio is re-encoded.

`amix` scales each input down so the sum does not clip. The two volume filters set the balance before that scaling. Adjust the two numbers until the voices and the music sit right, then run step 3 again.
