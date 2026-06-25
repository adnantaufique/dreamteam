#!/usr/bin/env bash
# Mirror the dreamteam skill into the CodeWhale skills layout (loaded via the /skills command).
# Usage: bash scripts/sync-to-codewhale.sh [target-dir]   (default: ~/.codewhale/skills/dreamteam)
set -euo pipefail
TARGET="${1:-$HOME/.codewhale/skills/dreamteam}"
mkdir -p "$TARGET"
cp -r skills/dreamteam/SKILL.md skills/dreamteam/references "$TARGET/"
echo "synced dreamteam -> $TARGET"
