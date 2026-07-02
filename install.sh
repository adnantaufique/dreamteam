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
root="$(cd "$(dirname "$0")" && pwd)"
SK="${HOME}/.claude/skills"
PL="${HOME}/.claude/plugins/cache"
dep_missing=0
have_plugin_skill() { find "$PL" -type d -path "*superpowers*/skills/$1" 2>/dev/null | grep -q .; }
have_dep_skill()    { [ -d "$SK/$1" ] || find "$PL" -type d -iname "*$1*" 2>/dev/null | grep -q .; }

# vendored agents that ship inside the plugin (path-registered in .claude-plugin/plugin.json)
bundled_agents=(
  vendor/agency-agents/ai-engineer.md             vendor/agency-agents/backend-architect.md
  vendor/agency-agents/code-reviewer.md           vendor/agency-agents/devops-automator.md
  vendor/agency-agents/frontend-developer.md      vendor/agency-agents/mobile-app-builder.md
  vendor/agency-agents/software-architect.md      vendor/agency-agents/technical-writer.md
  vendor/agency-agents/reality-checker.md         vendor/agency-agents/test-results-analyzer.md
  vendor/agency-agents/performance-benchmarker.md vendor/agency-agents/ui-designer.md
  vendor/ecc/methodology-reviewer.md              vendor/ecc/security-engineer.md
  vendor/ecc/build-error-resolver.md              vendor/ecc/pytorch-build-resolver.md
  vendor/superclaude/deep-research-agent.md       vendor/superclaude/quality-engineer.md
  vendor/superclaude/root-cause-analyst.md        vendor/superclaude/system-architect.md
  vendor/superclaude/python-expert.md
)

echo ""
echo "dependency check (bundled ship with the plugin; depended-on/optional resolve or substitute at runtime):"

# 1) bundled - vendored agents + the mle-workflow skill; ship with the plugin, never 'missing'
echo "  bundled (ship with the plugin):"
bundle_err=0
for f in "${bundled_agents[@]}"; do
  name="${f##*/}"; name="${name%.md}"
  if [ -f "$root/$f" ]; then echo "    [ok bundled] $name"; else echo "    [ERROR] missing from bundle: $f"; bundle_err=$((bundle_err+1)); fi
done
if [ -f "$root/skills/mle-workflow/SKILL.md" ]; then echo "    [ok bundled] mle-workflow (skill)"; else echo "    [ERROR] missing from bundle: skills/mle-workflow/SKILL.md"; bundle_err=$((bundle_err+1)); fi

# 2) depended-on - install via README Step 1, or the opt-in installer below
echo "  depended-on (superpowers + find-skills required via README Step 1; ui-ux-pro-max recommended):"
for s in brainstorming writing-plans using-git-worktrees verification-before-completion finishing-a-development-branch; do
  if have_plugin_skill "$s"; then echo "    [ok] superpowers:$s"; else echo "    [ ! ] superpowers:$s"; dep_missing=$((dep_missing+1)); fi
done
if have_dep_skill find-skills;   then echo "    [ok] find-skills"; else echo "    [ ! ] find-skills (needed for dynamic casting + the recommender)"; dep_missing=$((dep_missing+1)); fi
if have_dep_skill ui-ux-pro-max; then echo "    [ok] ui-ux-pro-max"; else echo "    [ ! ] ui-ux-pro-max (recommended - composed by the ux-designer / design roles when installed)"; dep_missing=$((dep_missing+1)); fi

# 3) optional - recommend-only; resolved or substituted at runtime
echo "  optional (recommend-only; resolved/substituted at runtime):"
for s in creative-thinking-for-research brainstorming-research-ideas literature-review ml-paper-writing architecture-reviewer; do
  if have_dep_skill "$s"; then echo "    [ok] $s"; else echo "    [recommend-only] $s (ai-research; install if you use that profile)"; fi
done
echo "    [built-in] Explore, general-purpose (host-resolved at runtime)"

echo ""
if [ "$bundle_err" -gt 0 ]; then
  echo "warning: $bundle_err bundled file(s) missing from this checkout - re-clone/re-pull the plugin."
fi
if [ "$dep_missing" -gt 0 ]; then
  echo "note: $dep_missing depended-on/recommended item(s) missing - a warning, not an error; paths needing them stay dark until installed."
else
  echo "all depended-on and recommended dependencies present."
fi

# --- opt-in dependency installer (strictly opt-in; default N; never auto-installs) ---
echo ""
echo "dependency install commands (1-2 required, per README Step 1; 3 recommended for the ux-designer / design roles):"
echo "  1) claude plugin marketplace add obra/superpowers-marketplace && claude plugin install superpowers@superpowers-marketplace"
echo "  2) npx skills add vercel-labs/skills --skill find-skills"
echo "  3) claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill && claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill"

if [ "$dep_missing" -gt 0 ] && [ -t 0 ]; then
  printf "Install the missing dependencies now? [y/N] "
  read -r reply || reply=""
  case "$reply" in
    y|Y)
      echo "installing missing dependencies (no auto-confirm flags)..."
      if command -v claude >/dev/null 2>&1; then
        claude plugin marketplace add obra/superpowers-marketplace \
          && claude plugin install superpowers@superpowers-marketplace \
          || echo "  superpowers: install failed - run command 1 above manually"
      else
        echo "  superpowers: 'claude' CLI not found - run command 1 above manually"
      fi
      if command -v npx >/dev/null 2>&1; then
        npx skills add vercel-labs/skills --skill find-skills \
          || echo "  find-skills: install failed - run command 2 above manually"
      else
        echo "  find-skills: 'npx' not found - run command 2 above manually"
      fi
      if command -v claude >/dev/null 2>&1; then
        claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill \
          && claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill \
          || echo "  ui-ux-pro-max: install failed - run command 3 above manually"
      else
        echo "  ui-ux-pro-max: 'claude' CLI not found - run command 3 above manually"
      fi
      echo "done. re-run ./install.sh to re-check."
      ;;
    *)
      echo "skipped (default N). run the commands above when ready."
      ;;
  esac
elif [ "$dep_missing" -gt 0 ]; then
  echo "(non-interactive shell - not prompting; run the commands above to install.)"
fi
