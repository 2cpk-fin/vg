# How to Install `vg`

Choose your agent environment below.

---

<details>
<summary><strong>Prompt-based Quick Install (All Agents)</strong></summary>

Copy and paste this single prompt directly into your AI assistant or coding agent:

```text
Install the vg skill/plugin from https://github.com/2cpk-fin/vg, refer to the repo's AGENTS.md for instructions.
```

Your agent will inspect `AGENTS.md`, check for `ffmpeg`, and automatically link the skill into its own configuration directory.

</details>

<details>
<summary><strong>Antigravity (AGY)</strong></summary>

### Quick Link
From a local clone:
```bash
bash install.sh
```

Or manually link:
```bash
mkdir -p ~/.gemini/config/skills
ln -sfn "$(pwd)" ~/.gemini/config/skills/vg
```

### Verification
```bash
ls -l ~/.gemini/config/skills/vg
```

</details>

<details>
<summary><strong>Claude Code</strong></summary>

### Install via Symlink
```bash
mkdir -p ~/.claude/skills
ln -sfn "$(pwd)" ~/.claude/skills/vg
```

Or run:
```bash
bash install.sh
```

</details>

<details>
<summary><strong>Cursor</strong></summary>

### User-wide Install
```bash
mkdir -p ~/.cursor/skills
ln -sfn "$(pwd)" ~/.cursor/skills/vg
```

### Via Agent Skills CLI (if repo is public)
```bash
npx skills add 2cpk-fin/vg -a cursor -g
```

</details>

<details>
<summary><strong>Codex CLI</strong></summary>

### User-wide Install
```bash
mkdir -p ~/.codex/skills
ln -sfn "$(pwd)" ~/.codex/skills/vg
```

### Via Agent Skills CLI (if repo is public)
```bash
npx skills add 2cpk-fin/vg -a codex
```

</details>

<details>
<summary><strong>Manual Clone & Install (Terminal)</strong></summary>

```bash
# 1. Clone repository
git clone https://github.com/2cpk-fin/vg.git
cd vg

# 2. Run multi-agent installer
bash install.sh
```

</details>

---

## Prerequisites

`vg` requires `ffmpeg` and `ffprobe` installed on the host system:

- **macOS**: `brew install ffmpeg`
- **Ubuntu / Debian**: `sudo apt update && sudo apt install -y ffmpeg`
- **Arch Linux**: `sudo pacman -S ffmpeg`
- **Windows**: `winget install Gyan.FFmpeg`
