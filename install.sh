#!/usr/bin/env bash
# vg — installer & symlinker for multi-agent environments.
# Links this skill directory to detected AI coding agents without duplicating files.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="vg"

# Known agent skill directories
GLOBAL_TARGETS=(
  "${HOME}/.gemini/config/skills/${SKILL_NAME}"
  "${HOME}/.claude/skills/${SKILL_NAME}"
  "${HOME}/.cursor/skills/${SKILL_NAME}"
  "${HOME}/.codex/skills/${SKILL_NAME}"
)

# Optional local project workspace target if run from within another workspace
LOCAL_TARGET=".agents/skills/${SKILL_NAME}"

echo "=== vg Skill Installer ==="
echo "Source: ${REPO_DIR}"

# Check system dependencies
missing_deps=()
command -v ffmpeg >/dev/null 2>&1 || missing_deps+=("ffmpeg")
command -v ffprobe >/dev/null 2>&1 || missing_deps+=("ffprobe")

if [ ${#missing_deps[@]} -gt 0 ]; then
  echo "[WARNING] Missing required system binaries: ${missing_deps[*]}"
  echo "Please install them via your package manager:"
  echo "  macOS:   brew install ffmpeg"
  echo "  Ubuntu:  sudo apt update && sudo apt install -y ffmpeg"
  echo "  Arch:    sudo pacman -S ffmpeg"
  echo "  Windows: winget install Gyan.FFmpeg"
else
  echo "[OK] System binaries found: ffmpeg, ffprobe"
fi

linked_count=0

# Link to global agent directories if parent exists or if explicit
for target in "${GLOBAL_TARGETS[@]}"; do
  parent_dir="$(dirname "${target}")"
  if [ -d "${parent_dir}" ]; then
    mkdir -p "${parent_dir}"
    ln -sfn "${REPO_DIR}" "${target}"
    echo "[LINKED] ${target} -> ${REPO_DIR}"
    linked_count=$((linked_count + 1))
  fi
done

# If no global agent directories existed, link to default Gemini/Antigravity skill path
if [ "${linked_count}" -eq 0 ]; then
  default_target="${HOME}/.gemini/config/skills/${SKILL_NAME}"
  mkdir -p "$(dirname "${default_target}")"
  ln -sfn "${REPO_DIR}" "${default_target}"
  echo "[DEFAULT] Created and linked: ${default_target} -> ${REPO_DIR}"
  linked_count=$((linked_count + 1))
fi

echo "=== vg skill linked successfully (${linked_count} target(s)) ==="
