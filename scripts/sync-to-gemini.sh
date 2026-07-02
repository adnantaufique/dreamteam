#!/usr/bin/env bash
# Mirror the dreamteam skill into the Gemini agents layout.
# Usage: bash scripts/sync-to-gemini.sh [target-dir]   (default: ~/.gemini/agents/dreamteam)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$HOME/.gemini/agents/dreamteam}"
mkdir -p "$TARGET"
cp -r "$REPO/skills/dreamteam/SKILL.md" "$REPO/skills/dreamteam/references" "$TARGET/"
cp -f "$REPO/GEMINI.md" "$REPO/gemini-extension.json" "$TARGET/" 2>/dev/null || true
echo "synced dreamteam -> $TARGET"
