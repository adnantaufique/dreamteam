#!/usr/bin/env bash
# Mirror the dreamteam skill into the Codex skills layout + add an AGENTS.md pointer.
# Usage: bash scripts/sync-to-codex.sh [target-dir]   (default: ~/.agents/skills/dreamteam)
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$HOME/.agents/skills/dreamteam}"
mkdir -p "$TARGET"
cp -r "$REPO/skills/dreamteam/SKILL.md" "$REPO/skills/dreamteam/references" "$TARGET/"
if [ -d "$HOME/.codex" ]; then
  grep -q "dreamteam" "$HOME/.codex/AGENTS.md" 2>/dev/null || printf -- '- dreamteam: see %s/SKILL.md (meta-orchestration skill)\n' "$TARGET" >> "$HOME/.codex/AGENTS.md"
else
  echo "codex not installed (no ~/.codex) -> skipped AGENTS.md pointer"
fi
echo "synced dreamteam -> $TARGET"
