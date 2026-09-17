# Agent Guide for `vg`

This file is the instruction guide for AI agents installing and operating [vg](https://github.com/2cpk-fin/vg). Read this file when instructed by the user to install or use `vg`.

---

## 1. Automated Installation for Agents

When a user prompts you:
```text
Install the vg skill/plugin from https://github.com/2cpk-fin/vg, refer to the repo's AGENTS.md for instructions.
```

Follow these exact steps:

### Step 1: Verify System Engine (`ffmpeg` and `ffprobe`)
Run:
```bash
command -v ffmpeg && command -v ffprobe
```
If missing:
- On Debian/Ubuntu: `sudo apt update && sudo apt install -y ffmpeg`
- On macOS: `brew install ffmpeg`
- On Windows: `winget install Gyan.FFmpeg`
- If you lack root/sudo, inform the user to install `ffmpeg`.

### Step 2: Clone or Symlink to Your Agent's Skill Directory

#### For Antigravity / Gemini CLI:
Run from the repository root:
```bash
mkdir -p "${HOME}/.gemini/config/skills"
ln -sfn "$(pwd)" "${HOME}/.gemini/config/skills/vg"
```
Or execute `./install.sh`.

#### For Claude Code:
```bash
mkdir -p "${HOME}/.claude/skills"
ln -sfn "$(pwd)" "${HOME}/.claude/skills/vg"
```

#### For Cursor:
```bash
mkdir -p "${HOME}/.cursor/skills"
ln -sfn "$(pwd)" "${HOME}/.cursor/skills/vg"
```

#### Universal / Local Project:
```bash
mkdir -p .agents/skills
ln -sfn "$(pwd)" .agents/skills/vg
```

### Step 3: Verification
Confirm that `SKILL.md` is present and accessible:
```bash
ls -la "${HOME}/.gemini/config/skills/vg/SKILL.md" 2>/dev/null || ls -la ".agents/skills/vg/SKILL.md"
```
Report success to the user with next steps (e.g. "Drop raw videos into staging/ to begin ingestion").

---

## 2. Repository Map

| Path | Purpose |
| --- | --- |
| `SKILL.md` | Canonical skill definition, editorial rules, and subagent orchestration. |
| `install.sh` | Portable bash installer linking the skill to detected agent runtimes. |
| `staging/` | Input directory for unindexed raw video files. |
| `prod/` | Processed asset vault containing indexed videos. |
| `output/` | Destination folder for crafted videos rendered from prompts. |
| `index.jsonl` | Append-only Action Dictionary mapping timestamped semantic blocks to clips in `prod/`. |
| `references/ffmpeg_cheatsheet.md` | Dynamic FFmpeg command recipes for inspection, silence detection, cut, and concat. |

---

## 3. Core Behavioral Mandates

1. **Zero Hardcoding**: Never invent timestamps, durations, or scene descriptions. All values must be dynamically queried using `ffprobe` or `ffmpeg`.
2. **Atomic Transitions**: When ingesting, write JSONL entries to `index.jsonl` first, then run `mv staging/<file> prod/<file>`.
3. **Cut Boundaries**: Always verify silence and scene change intervals to prevent mid-word or mid-action cutting.
