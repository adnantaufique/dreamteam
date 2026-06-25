#!/usr/bin/env bash
# Mirror the dreamteam skill into the Codex skills layout + add an AGENTS.md pointer.
# Usage: bash scripts/sync-to-codex.sh [target-dir]   (default: ~/.agents/skills/dreamteam)
set -euo pipefail
TARGET="${1:-$HOME/.agents/skills/dreamteam}"
mkdir -p "$TARGET"
cp -r skills/dreamteam/SKILL.md skills/dreamteam/references "$TARGET/"
grep -q "dreamteam" AGENTS.md 2>/dev/null || printf -- '- dreamteam: see %s/SKILL.md (meta-orchestration skill)\n' "$TARGET" >> AGENTS.md
echo "synced dreamteam -> $TARGET"
