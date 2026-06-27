#!/usr/bin/env bash
# Mirror the dreamteam skill into OpenCode's native Agent-Skills layout (loaded on-demand via the native `skill` tool).
# Usage: bash scripts/sync-to-opencode.sh [target-dir]   (default: ~/.config/opencode/skills/dreamteam)
# Note: OpenCode also natively reads ~/.claude/skills, so a dreamteam installed via install.sh is already discoverable — this sync is for OpenCode-only setups.
set -euo pipefail
TARGET="${1:-$HOME/.config/opencode/skills/dreamteam}"
mkdir -p "$TARGET"
cp -r skills/dreamteam/SKILL.md skills/dreamteam/references "$TARGET/"
echo "synced dreamteam -> $TARGET"
