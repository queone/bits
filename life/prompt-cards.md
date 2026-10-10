---
type: reference
---
## Prompt Cards

Four how-tos retired from this site, each reduced to the shortest prompt that reproduces it and the choices the prompt has to carry. Ask a model with the prompt, then check its answer against the choices. All four use [FFmpeg](https://en.wikipedia.org/wiki/FFmpeg) or an Apple app.

### Rip a disc for Apple TV

- Prompt: "MakeMKV rip, then ffmpeg MKV to MP4 for Apple TV: copy video, AC3 audio at 640k."
- Choices: [MakeMKV](https://www.makemkv.com/) keeps the disc's full quality in [MKV](https://en.wikipedia.org/wiki/Matroska), the archival copy. The MP4 copies the video stream and re-encodes the audio to AC3 at 640k, which the Apple TV app plays.

### Crop a clip to 4:3

- Prompt: "ffmpeg: center-crop 16:9 to 4:3, copy audio."
- Choices: the new width is the input height times four thirds, the crop is centered, and the audio stream is copied rather than re-encoded.

### iPhone ringtones

- Prompt: "ffmpeg: MP3 or WAV to iPhone ringtone, 40-second cap, ipod format, AAC at 256k; and ringtone back to MP3."
- Choices: a [ringtone](https://en.wikipedia.org/wiki/Ringtone) is an M4R file of 40 seconds or less, written with the ipod output format. Metadata edits copy the streams so nothing is re-encoded.

### Home videos on Apple TV

- Prompt: "Share a Mac folder of MP4s to an Apple TV through the Apple TV app and Media Sharing."
- Choices: import the folder in the [Apple TV app](https://en.wikipedia.org/wiki/Apple_TV_app), turn on Media Sharing in System Settings. Keep both devices on one Wi-Fi network and one Apple ID, and leave the Mac on to serve the videos.

Kept as a how-to: [Mix Music Into a Video](mix-music-video.md). Its prompt would have to carry the volume balance, the seek placed before the input, and the stop at the clip's end. That is a how-to's worth of choices.
