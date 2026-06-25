#!/usr/bin/env bash
# Manual install of the dreamteam skill to ~/.claude/skills/dreamteam (Linux/macOS),
# then a best-effort dependency check. Plugin users can instead run:
#   /plugin marketplace add <owner>/dreamteam  &&  /plugin install dreamteam@dreamteam-marketplace
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/skills/dreamteam"
dst="${HOME}/.claude/skills/dreamteam"

rm -rf "$dst"                 # clean mirror: prune stale files
mkdir -p "$dst"
cp -R "$src/." "$dst/"

if [ -f "$dst/SKILL.md" ]; then
  echo "installed dreamteam skill -> $dst"
else
  echo "install failed: SKILL.md not found in $dst" >&2
  exit 1
fi

# --- dependency check (best-effort; dreamteam also resolves/substitutes at runtime) ---
SK="${HOME}/.claude/skills"
PL="${HOME}/.claude/plugins/cache"
AG="${HOME}/.claude/agents"
missing=0
have_plugin_skill() { find "$PL" -type d -path "*superpowers*/skills/$1" 2>/dev/null | grep -q .; }
have_agent() { local n; n=$(printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-'); find "$AG" -type f -iname "*$n.md" 2>/dev/null | grep -q .; }

echo ""
echo "dependency check (missing items are resolved/substituted at runtime via the Caster + find-skills):"
echo "  required sub-skills (superpowers plugin):"
for s in brainstorming writing-plans using-git-worktrees verification-before-completion finishing-a-development-branch; do
  if have_plugin_skill "$s"; then echo "    [ok] superpowers:$s"; else echo "    [ ! ] superpowers:$s  -> install the 'superpowers' plugin"; missing=$((missing+1)); fi
done
echo "  skills (~/.claude/skills):"
for s in find-skills creative-thinking-for-research brainstorming-research-ideas literature-review ml-paper-writing architecture-reviewer; do
  if [ -d "$SK/$s" ]; then echo "    [ok] $s"; else echo "    [ ! ] $s"; missing=$((missing+1)); fi
done
echo "  profile agents (used per profile; general-purpose is built-in):"
for a in "Reality Checker" "Code Reviewer" "AI Engineer" "Backend Architect" "Frontend Developer" "UI Designer" "UX Architect" "Mobile App Builder" "DevOps Automator" "Security Engineer" "Technical Writer" "Test Results Analyzer" "Performance Benchmarker" "deep-research-agent" "system-architect" "quality-engineer" "root-cause-analyst" "Explore" "Software Architect"; do
  if have_agent "$a"; then echo "    [ok] $a"; else echo "    [ ! ] $a  (may be built-in/plugin; verified at runtime)"; missing=$((missing+1)); fi
done
if [ "$missing" -gt 0 ]; then
  echo "note: $missing item(s) not found on disk - a warning, not an error; dreamteam substitutes/flags them at runtime."
else
  echo "all listed dependencies found."
fi
