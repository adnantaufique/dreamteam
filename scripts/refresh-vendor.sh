#!/usr/bin/env bash
# refresh-vendor.sh — dreamteam vendor-refresh guardrail (build-plan PHASE J / P2-20).
#
# For each vendored source (agency-agents, ECC, SuperClaude) at the commit pinned in
# THIRD_PARTY_NOTICES.md, this re-fetches every vendored file from raw.githubusercontent.com
# and verifies the local copy under vendor/ (and skills/mle-workflow/) has NOT drifted from
# upstream, then verifies each source LICENSE is retained, still MIT, matches upstream, and
# has a THIRD_PARTY_NOTICES entry for the pinned commit.
#
# Drift comparison IGNORES the two metadata-only changes the vendoring convention allows
# (THIRD_PARTY_NOTICES.md "Vendoring convention"): the single added column-0 `origin:`
# frontmatter line (all files) and the `name:` rename (only the two renamed ECC agents,
# mle-reviewer -> methodology-reviewer and security-reviewer -> Security Engineer). The
# prompt BODY is compared byte-for-byte and must stay pristine.
#
# Read-only: it never writes to vendor/. It is the verification gate that must pass before
# (and after) any SHA bump / vendor refresh, and the same check the CI license-gate runs.
#
# The SHAs, repo paths, and file lists below are taken VERBATIM from THIRD_PARTY_NOTICES.md —
# no SHA or path is invented. Prints a per-file PASS/DRIFT report and exits NON-ZERO on any
# drift or license change.
#
# Usage: bash scripts/refresh-vendor.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="https://raw.githubusercontent.com"
TPN="$ROOT/THIRD_PARTY_NOTICES.md"

# --- pinned commits (verbatim from THIRD_PARTY_NOTICES.md) ---
SHA_AGENCY="1189f0f9bc79a1883fee958fed627c6d11581eb7"   # msitarzewski/agency-agents
SHA_ECC="2bc924faf2f8e893bfe0af86b1931283693c30ae"      # affaan-m/ECC
SHA_SC="226c45cc93b865108843a669c6545d421784b68c"       # SuperClaude-Org/SuperClaude_Framework

fail=0
pass=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Normalize for the pristine-body diff: strip CR; inside the leading YAML frontmatter drop a
# column-0 `origin:` line, and (when strip_name=1) a `name:` line. Body is left untouched.
normalize() { # <file> <strip_name>
  awk -v sn="$2" '
    { sub(/\r$/, "") }
    $0 == "---" { if (seen==0) {infm=1; seen=1; print; next} else if (infm==1) {infm=0; print; next} }
    infm==1 && /^origin:/ { next }
    infm==1 && sn==1 && /^name:/ { next }
    { print }
  ' "$1"
}

check_file() { # <owner/repo> <sha> <upstream_path> <local_path> <renamed 0|1>
  local repo="$1" sha="$2" up="$3" loc="$4" ren="$5"
  local url="$RAW/$repo/$sha/$up"
  local lp="$ROOT/$loc"
  if [ ! -f "$lp" ]; then
    printf '  DRIFT  %s  (local file missing)\n' "$loc"; fail=$((fail+1)); return
  fi
  if ! curl -fsSL "$url" -o "$tmp/up.raw"; then
    printf '  DRIFT  %s  (upstream fetch failed: %s)\n' "$loc" "$url"; fail=$((fail+1)); return
  fi
  normalize "$lp" "$ren" > "$tmp/l.norm"
  normalize "$tmp/up.raw" "$ren" > "$tmp/u.norm"
  if diff -q "$tmp/l.norm" "$tmp/u.norm" >/dev/null; then
    printf '  PASS   %s\n' "$loc"; pass=$((pass+1))
  else
    printf '  DRIFT  %s  (body differs from upstream %s)\n' "$loc" "$up"; fail=$((fail+1))
    diff "$tmp/u.norm" "$tmp/l.norm" | sed 's/^/         /' | head -n 8
  fi
}

check_license() { # <owner/repo> <sha> <local_dir>
  local repo="$1" sha="$2" dir="$3"
  local lp="$ROOT/$dir/LICENSE"
  local url="$RAW/$repo/$sha/LICENSE"
  if [ ! -f "$lp" ]; then
    printf '  DRIFT  %s/LICENSE  (retained LICENSE missing)\n' "$dir"; fail=$((fail+1)); return
  fi
  if ! grep -q "MIT License" "$lp"; then
    printf '  DRIFT  %s/LICENSE  (local LICENSE is not MIT)\n' "$dir"; fail=$((fail+1)); return
  fi
  if ! curl -fsSL "$url" -o "$tmp/lic.raw"; then
    printf '  DRIFT  %s/LICENSE  (upstream LICENSE fetch failed)\n' "$dir"; fail=$((fail+1)); return
  fi
  if ! grep -q "MIT License" "$tmp/lic.raw"; then
    printf '  DRIFT  %s/LICENSE  (upstream LICENSE no longer MIT at %s)\n' "$dir" "$sha"; fail=$((fail+1)); return
  fi
  tr -d '\r' < "$lp"          > "$tmp/lic.local"
  tr -d '\r' < "$tmp/lic.raw" > "$tmp/lic.up"
  if ! diff -q "$tmp/lic.local" "$tmp/lic.up" >/dev/null; then
    printf '  DRIFT  %s/LICENSE  (retained LICENSE differs from upstream)\n' "$dir"; fail=$((fail+1)); return
  fi
  if ! grep -q "$sha" "$TPN"; then
    printf '  DRIFT  %s/LICENSE  (no THIRD_PARTY_NOTICES entry for %s)\n' "$dir" "$sha"; fail=$((fail+1)); return
  fi
  printf '  PASS   %s/LICENSE  (MIT, retained verbatim, notices entry present)\n' "$dir"; pass=$((pass+1))
}

echo "dreamteam vendor-refresh guardrail — drift + license gate"
echo "(SHAs/paths verbatim from THIRD_PARTY_NOTICES.md; ignoring the added origin: line + the ECC name: rename)"

echo
echo "agency-agents @ $SHA_AGENCY  (msitarzewski/agency-agents)"
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-ai-engineer.md"        "vendor/agency-agents/ai-engineer.md"           0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-backend-architect.md"  "vendor/agency-agents/backend-architect.md"     0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-code-reviewer.md"       "vendor/agency-agents/code-reviewer.md"         0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-devops-automator.md"    "vendor/agency-agents/devops-automator.md"      0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-frontend-developer.md"  "vendor/agency-agents/frontend-developer.md"    0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-mobile-app-builder.md"  "vendor/agency-agents/mobile-app-builder.md"    0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-software-architect.md"  "vendor/agency-agents/software-architect.md"    0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "engineering/engineering-technical-writer.md"    "vendor/agency-agents/technical-writer.md"      0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "testing/testing-reality-checker.md"             "vendor/agency-agents/reality-checker.md"       0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "testing/testing-test-results-analyzer.md"       "vendor/agency-agents/test-results-analyzer.md" 0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "testing/testing-performance-benchmarker.md"     "vendor/agency-agents/performance-benchmarker.md" 0
check_file "msitarzewski/agency-agents" "$SHA_AGENCY" "design/design-ui-designer.md"                   "vendor/agency-agents/ui-designer.md"           0
check_license "msitarzewski/agency-agents" "$SHA_AGENCY" "vendor/agency-agents"

echo
echo "ECC @ $SHA_ECC  (affaan-m/ECC)"
check_file "affaan-m/ECC" "$SHA_ECC" "agents/mle-reviewer.md"          "vendor/ecc/methodology-reviewer.md"  1
check_file "affaan-m/ECC" "$SHA_ECC" "agents/security-reviewer.md"     "vendor/ecc/security-engineer.md"     1
check_file "affaan-m/ECC" "$SHA_ECC" "agents/build-error-resolver.md"  "vendor/ecc/build-error-resolver.md"  0
check_file "affaan-m/ECC" "$SHA_ECC" "agents/pytorch-build-resolver.md" "vendor/ecc/pytorch-build-resolver.md" 0
check_file "affaan-m/ECC" "$SHA_ECC" "skills/mle-workflow/SKILL.md"    "skills/mle-workflow/SKILL.md"        0
check_license "affaan-m/ECC" "$SHA_ECC" "vendor/ecc"

echo
echo "SuperClaude @ $SHA_SC  (SuperClaude-Org/SuperClaude_Framework)"
check_file "SuperClaude-Org/SuperClaude_Framework" "$SHA_SC" "plugins/superclaude/agents/deep-research-agent.md" "vendor/superclaude/deep-research-agent.md" 0
check_file "SuperClaude-Org/SuperClaude_Framework" "$SHA_SC" "plugins/superclaude/agents/quality-engineer.md"    "vendor/superclaude/quality-engineer.md"    0
check_file "SuperClaude-Org/SuperClaude_Framework" "$SHA_SC" "plugins/superclaude/agents/root-cause-analyst.md"  "vendor/superclaude/root-cause-analyst.md"  0
check_file "SuperClaude-Org/SuperClaude_Framework" "$SHA_SC" "plugins/superclaude/agents/system-architect.md"    "vendor/superclaude/system-architect.md"    0
check_file "SuperClaude-Org/SuperClaude_Framework" "$SHA_SC" "plugins/superclaude/agents/python-expert.md"       "vendor/superclaude/python-expert.md"       0
check_license "SuperClaude-Org/SuperClaude_Framework" "$SHA_SC" "vendor/superclaude"

echo
echo "----------------------------------------------------------------"
printf 'result: %d PASS, %d DRIFT\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
  echo "FAIL: vendored files drifted from their pinned upstream, or a LICENSE changed."
  echo "      Bodies must stay pristine (only the added origin: line + the documented ECC name: rename are allowed)."
  exit 1
fi
echo "OK: every vendored file matches its pinned upstream; all LICENSEs are MIT and retained."
exit 0
