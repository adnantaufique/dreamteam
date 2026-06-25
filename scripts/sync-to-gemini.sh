#!/usr/bin/env bash
# Mirror the dreamteam skill into the Gemini agents layout.
# Usage: bash scripts/sync-to-gemini.sh [target-dir]   (default: ~/.gemini/agents/dreamteam)
set -euo pipefail
TARGET="${1:-$HOME/.gemini/agents/dreamteam}"
mkdir -p "$TARGET"
cp -r skills/dreamteam/SKILL.md skills/dreamteam/references "$TARGET/"
cp -f GEMINI.md gemini-extension.json "$TARGET/" 2>/dev/null || true
echo "synced dreamteam -> $TARGET"
