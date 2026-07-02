#!/usr/bin/env bash
# Mirror the dreamteam skill into the CodeWhale skills layout (loaded via the /skills command).
# Usage: bash scripts/sync-to-codewhale.sh [target-dir]   (default: ~/.codewhale/skills/dreamteam)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$HOME/.codewhale/skills/dreamteam}"
mkdir -p "$TARGET"
cp -r "$REPO/skills/dreamteam/SKILL.md" "$REPO/skills/dreamteam/references" "$TARGET/"
echo "synced dreamteam -> $TARGET"
