# vg

**Autonomous semantic video engine for AI coding agents. Craft videos directly from prompts using your agent's eyes and FFmpeg.**

---

## Install

Copy/paste into your CLI prompt:

```text
Install the vg skill/plugin from https://github.com/2cpk-fin/vg, refer to the repo's AGENTS.md for instructions.
```

Or 🔗 [check the installation instructions](INSTALL.md).

---

## What it does

An autonomous video skill for your AI agent that ingests raw video footage, semantically indexes actions and speech with frame-accurate timestamps into an **Action Dictionary**, and assembles finished videos on demand matching your prompt.

- **Zero API keys**: The agent's native multimodal vision and reasoning is the brain.
- **Zero hardcoding**: All metadata, durations, cuts, and silence intervals are extracted dynamically with `ffprobe` and `ffmpeg`.
- **Atomic staging-to-prod pipeline**: Drops into `staging/`, indexes into `index.jsonl`, moves to `prod/`.
- **Instant prompt crafting**: Queries the dictionary to assemble 15s/30s/60s cuts without re-watching gigabytes of footage.

---

## Quick Start

### 1. Ingest Footage
Drop raw clips (`.mp4`, `.mov`, `.mkv`) into `staging/` and tell your agent:
> *"Ingest the new videos in staging."*

The agent will fan out subagents, inspect keyframes and audio, append entries to `index.jsonl`, and move completed files to `prod/`.

### 2. Craft a Video
Tell your agent what you want:
> *"Craft a 20s energetic video highlighting action shots from prod."*

The agent queries `index.jsonl`, builds a frame-accurate timeline, renders via FFmpeg, and delivers the finished file to `output/`.

---

## Documentation

- [Installation Guide (all platforms)](INSTALL.md)
- [Agent Guide & Integration Map](AGENTS.md)
- [Skill Specification & Editorial Rules](SKILL.md)
- [FFmpeg Command Cheatsheet](references/ffmpeg_cheatsheet.md)

---

## License

MIT
