---
name: vg
description: >-
  Autonomous video ingestion, semantic action-indexing, and prompt-driven video crafting using FFmpeg and dynamic subagent fan-out.
  Use when the user wants to ingest raw videos from staging/ to prod/, index actions into index.jsonl, or craft videos from prompts.
---

# `vg`: Autonomous Semantic Video Engine

A zero-dependency, pure-agentic skill for video asset management and semantic editing.
Operates on two principles:
1. **The Agent is the Brain**: AI performs all visual inspection, narrative planning, and timestamp decisions. No external APIs or hardcoded scripts.
2. **Strict Anti-Hardcoding**: Never invent timestamps, frame numbers, or scene descriptions. Every metadata entry and cut point MUST be derived dynamically from real `ffprobe` and `ffmpeg` outputs.

---

## Workspace Directory Structure

```text
vg/
├── SKILL.md            # Execution playbook and editorial rules
├── install.sh          # Agent environment symlinker
├── staging/            # Input queue: Drop unindexed raw videos here
├── prod/               # Asset vault: Successfully indexed videos reside here
├── output/             # Delivery: Rendered videos created from prompts
├── index.jsonl         # Action Dictionary: Semantic index of all blocks in prod/
└── references/
    └── ffmpeg_cheatsheet.md # Dynamic FFmpeg command recipes
```

---

## Operational Modes

The skill operates in two distinct modes depending on the user's request:
- **Mode 1: INGEST (`staging/` -> `prod/`)**: Process unindexed raw footage into the Action Dictionary.
- **Mode 2: CRAFT (`prod/` -> `output/`)**: Search `index.jsonl` and assemble a video matching a prompt.

---

## Mode 1: INGEST Workflow (Staging to Prod)

Execute this workflow when new videos are present in `staging/` or when the user requests an ingest/index operation.

### Step 1: Discover New Files
Run a dynamic directory check:
```bash
find staging/ -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.mov" -o -name "*.mkv" -o -name "*.avi" -o -name "*.webm" \)
```
If `staging/` is empty, inform the user and skip ingestion.

### Step 2: Parallel Dynamic Fan-Out
For each video file found in `staging/`, spawn a dedicated subagent using `invoke_subagent`:
- **TypeName**: `self`
- **Role**: `Clip Ingestion Scout`
- **Prompt**: Instruct the subagent to:
  1. Measure exact file duration and specs using `ffprobe`:
     ```bash
     ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE"
     ```
  2. Extract visual keyframes to a private temp directory (e.g. `.temp/<file_basename>_frames/`):
     ```bash
     mkdir -p ".temp/${BASE}_frames"
     ffmpeg -i "$VIDEO_FILE" -vf "select='gt(scene,0.35)',showinfo" -vsync vfr -frame_pts 1 ".temp/${BASE}_frames/scene_%04d.jpg"
     ```
     *(If scene detection yields fewer than 3 frames, fall back to `fps=1/2` periodic sampling).*
  3. Detect speech/silence boundaries to avoid mid-word cuts:
     ```bash
     ffmpeg -i "$VIDEO_FILE" -af silencedetect=noise=-30dB:d=0.25 -f null - 2>&1 | grep -E "silence_(start|end)" || true
     ```
  4. Inspect the extracted `.jpg` images using `view_file` to evaluate visual content, actions, camera framing, subject, and mood.
  5. Segment the video into coherent **Action Blocks (2 to 8 seconds each)**.
     - **Strict Cut Alignment**: Snap each block's start and end timestamps to detected scene boundaries or silence intervals. Never cut mid-sentence or mid-action.
  6. Format findings as JSON Lines targeting the future `prod/` path:
     ```json
     {"clip": "prod/<filename>", "start": "00:00:02.100", "end": "00:00:07.450", "action": "<precise description of action>", "subject": "<subject description>", "shot": "<wide|medium|close-up|aerial>", "mood": "<emotional vibe>", "speech": "<speech transcript or empty>", "quality": <1-10 integer>}
     ```
  7. Delete the temporary frames folder (`rm -rf ".temp/${BASE}_frames"`).
  8. Return the JSONL lines in the final message.

### Step 3: Atomic Ingestion & State Update
Upon receiving verified JSONL entries from the subagent:
1. Append the new JSON lines directly to `index.jsonl`:
   ```bash
   cat << 'EOF' >> index.jsonl
   <received_json_lines>
   EOF
   ```
2. Atomically move the processed video file:
   ```bash
   mv "staging/<filename>" "prod/<filename>"
   ```
3. Repeat for all files in `staging/`.

---

## Mode 2: CRAFT Workflow (Prompt to Video)

Execute this workflow when the user requests a video to be created or edited based on a prompt.

### Step 1: Analyze Request Parameters
Identify:
- **Target Duration**: (e.g., 15s, 30s, 60s). If unspecified, default to 30 seconds.
- **Narrative Arc & Mood**: (e.g., fast-paced energetic montage, slow emotional narrative, tutorial intro).
- **Target Aspect Ratio**: Standard 16:9 (1920x1080) or Vertical 9:16 (1080x1920). Default to 16:9 unless requested.

### Step 2: Query the Action Dictionary
Inspect `index.jsonl` without re-reading raw videos:
```bash
grep -i "<keyword_or_mood>" index.jsonl || head -n 50 index.jsonl
```
Select the highest quality blocks (`quality >= 7`) that collectively fulfill the narrative arc:
- **Hook (0-5s)**: High visual energy, clear establishing shot or immediate action.
- **Body/Development**: Thematic actions supporting the prompt.
- **Climax / Resolution**: Satisfying wrap-up shot or closing action.

### Step 3: Build the Edit Decision List (EDL)
Calculate the exact running time:
$$\sum (\text{end}_i - \text{start}_i) \approx \text{Target Duration}$$
Verify that all referenced files exist in `prod/`.

### Step 4: Frame-Accurate Cut & Normalize
Create temporary workspace `.temp/cuts/`.
Cut each selected block using frame-accurate encoding and uniform resolution/framerate:
```bash
mkdir -p .temp/cuts

# Example cut 1 (Normalized 1080p 16:9, 30fps):
ffmpeg -y -ss <start> -to <end> -i "prod/<clip_name>" \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30" \
  -c:v libx264 -crf 18 -preset fast -c:a aac -ar 48000 -ac 2 -b:a 192k .temp/cuts/cut_001.mp4
```
Repeat for all blocks in the timeline.

### Step 5: Concat & Deliver
1. Generate the demuxer list:
   ```bash
   printf "file '%s'\n" .temp/cuts/*.mp4 > .temp/concat_list.txt
   ```
2. Lossless stitch to `output/`:
   ```bash
   ffmpeg -y -f concat -safe 0 -i .temp/concat_list.txt -c copy "output/<semantic_name>.mp4"
   ```
3. Remove temporary cuts:
   ```bash
   rm -rf .temp/
   ```
4. Verify the output video duration:
   ```bash
   ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "output/<semantic_name>.mp4"
   ```
5. Report the output file path and timeline breakdown to the user.

---

## Anti-Hardcoding & Quality Mandates

- **Zero Mock Data**: Never write placeholder timestamps like `00:00:00` or fake action descriptions into `index.jsonl`.
- **Verify Input Existence**: If `staging/` is empty during Ingest, or `prod/` is empty during Craft, state the exact directory status immediately.
- **Silence & Scene Protection**: Never split a spoken sentence mid-word. Use `ffmpeg silencedetect` to verify boundaries before writing to `index.jsonl`.
- **Non-Destructive Execution**: Raw videos are never deleted; they are only moved from `staging/` to `prod/`.
