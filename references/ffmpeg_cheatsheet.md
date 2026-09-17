# FFmpeg Reference Recipes for Autonomous Agent Execution

This document provides exact, battle-tested FFmpeg CLI commands.
**CRITICAL:** Never hardcode timestamps or dimensions. Always read actual values dynamically from `ffprobe`.

---

## 1. Dynamic Video Inspection (Metadata)

### Get Exact Duration (seconds)
```bash
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4
```

### Get Resolution and FPS
```bash
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,codec_name -of json input.mp4
```

### Check If Audio Stream Exists
```bash
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 input.mp4
```

---

## 2. Visual Sampling for Agent Inspection

### Extract Scene Change Keyframes (Best for cuts/angles)
```bash
mkdir -p .temp/frames
ffmpeg -i input.mp4 -vf "select='gt(scene,0.35)',showinfo" -vsync vfr -frame_pts 1 .temp/frames/scene_%04d.jpg
```

### Periodic Grid/FPS Sampling (e.g., 1 frame every 2 seconds)
```bash
mkdir -p .temp/frames
ffmpeg -i input.mp4 -vf "fps=1/2" .temp/frames/sample_%04d.jpg
```

---

## 3. Audio & Speech Boundary Detection

### Detect Silence Intervals (Prevents cutting mid-word)
Detects silence longer than 0.25 seconds below -30dB:
```bash
ffmpeg -i input.mp4 -af silencedetect=noise=-30dB:d=0.25 -f null - 2>&1 | grep -E "silence_(start|end)"
```
*   `silence_start`: Time when speech stopped. Safe cut window opens.
*   `silence_end`: Time when speech resumes. Safe cut window closes.
*   **Rule:** Snapping points must be inside `[silence_start + 0.05, silence_end - 0.05]`.

---

## 4. Frame-Accurate Cutting

### Precise Millisecond Cut
Always place `-ss` and `-to` before or after `-i` with re-encoding to avoid frozen I-frame artifacts:
```bash
ffmpeg -y -ss 00:01:14.250 -to 00:01:22.800 -i input.mp4 -c:v libx264 -crf 18 -preset fast -c:a aac -b:a 192k output_cut.mp4
```

### Standardizing Cuts Before Concat (Prevent Resolution/FPS Mismatch)
If combining clips with differing resolutions/framerates into 1080p 16:9 (1920x1080, 30fps):
```bash
ffmpeg -y -ss 00:01:14.250 -to 00:01:22.800 -i input.mp4 \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30" \
  -c:v libx264 -crf 18 -preset fast -c:a aac -ar 48000 -ac 2 -b:a 192k cut_normalized.mp4
```

For 9:16 Vertical (1080x1920 Shorts/TikTok/Reels):
```bash
ffmpeg -y -ss 00:01:14.250 -to 00:01:22.800 -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30" \
  -c:v libx264 -crf 18 -preset fast -c:a aac -ar 48000 -ac 2 -b:a 192k cut_normalized.mp4
```

---

## 5. Lossless Concatenation

### Using Concat Demuxer
Create `concat_list.txt`:
```text
file 'cuts/cut_01.mp4'
file 'cuts/cut_02.mp4'
file 'cuts/cut_03.mp4'
```

Execute lossless stitch:
```bash
ffmpeg -y -f concat -safe 0 -i concat_list.txt -c copy final_output.mp4
```

---

## 6. Cleanup

Always clean up `.temp/` frame directories after analysis:
```bash
rm -rf .temp/
```
