#!/usr/bin/env bash
# Mirror the dreamteam skill into Cursor's native Agent-Skills layout (auto-matched on the skill description).
# Usage: bash scripts/sync-to-cursor.sh [target-dir]   (default: ~/.cursor/skills/dreamteam)
# Note: Cursor also reads ~/.claude/skills for compatibility, so a dreamteam installed via install.sh is already discoverable — this sync is for Cursor-only setups.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$HOME/.cursor/skills/dreamteam}"
mkdir -p "$TARGET"
cp -r "$REPO/skills/dreamteam/SKILL.md" "$REPO/skills/dreamteam/references" "$TARGET/"
echo "synced dreamteam -> $TARGET"
