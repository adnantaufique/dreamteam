#!/usr/bin/env bash
# Live spot-check runner for tests/scenarios.md - executes selected scenarios as headless dry-runs.
# Each scenario = TWO billed `claude -p` calls (run + judge). No default set - IDs are explicit.
# Usage: bash tests/run-scenarios.sh [--list] [--extract] <ID ...>   e.g. S49 S50 GroundingA
set -euo pipefail
TESTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$TESTS")"
SCEN="$TESTS/scenarios.md"; SKILL="$REPO/skills/dreamteam"
TIMEOUT_SECS="${TIMEOUT_SECS:-180}"
TMP="$(mktemp -d)"

usage() {
  echo "usage: bash tests/run-scenarios.sh [--list] [--extract] <ID ...>   e.g. S49 S50 GroundingA"
  echo "  --list      print available scenario IDs and exit"
  echo "  --extract   print each ID's parsed block + cited files and exit (no model calls)"
  echo "  TIMEOUT_SECS=$TIMEOUT_SECS per claude call (env-overridable)"
  echo "COST: each selected scenario spends TWO headless 'claude -p' model calls (billed)."
}
ids_available() { grep -oE '^## (S[0-9]+|Grounding [AB]) ' "$SCEN" | sed 's/^## //; s/ *$//; s/Grounding /Grounding/'; }
canon_id() {
  local want c; want="$(printf '%s' "$1" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')"
  ids_available | while read -r c; do
    [ "$(printf '%s' "$c" | tr '[:upper:]' '[:lower:]')" = "$want" ] && { printf '%s\n' "$c"; break; }
  done || true   # no-match must not trip set -e: caller's unknown-id ERROR row handles it
}
block_of() { # canonical ID -> scenario block (heading .. before next '## ' or '> ' blockquote)
  local h; case "$1" in GroundingA) h="## Grounding A ";; GroundingB) h="## Grounding B ";; *) h="## $1 ";; esac
  awk -v h="$h" '!f && index($0,h)==1 {f=1; print; next} f && (/^## / || /^> /) {exit} f {print}' "$SCEN"
}
cited_files() { # stdin: heading + Input text -> existing skill-file paths, deduped ("installed skill" = whole tree)
  local t; t="$(cat)"
  { printf '%s' "$t" | grep -qiE 'installed(/fixed)? (skill|`)' && { echo "$SKILL/SKILL.md"; printf '%s\n' "$SKILL/references/"*.md; } || true
    printf '%s' "$t" | grep -oE 'references/[A-Za-z0-9_-]+\.md' | sed "s|^|$SKILL/|" || true
    printf '%s' "$t" | grep -q 'SKILL\.md' && echo "$SKILL/SKILL.md" || true
    printf '%s' "$t" | grep -oE '`[a-z0-9_-]+\.md`' | tr -d '`' | sed "s|^|$SKILL/references/|" || true
  } | awk '!seen[$0]++' | while read -r f; do if [ -f "$f" ]; then printf '%s\n' "$f"; fi; done
}
claude_call() { # $1=prompt file  $2=stdout file -> sets RC (124 = timeout). Never call via $(...).
  local pid wd
  claude -p <"$1" >"$2" 2>"$2.err" & pid=$!
  ( trap 'kill "$s" 2>/dev/null; exit 0' TERM   # reap our own sleep so no child outlives the watchdog
    sleep "$TIMEOUT_SECS" & s=$!
    wait "$s" || exit 0
    kill "$pid" 2>/dev/null && : >"$2.timeout"
  ) >/dev/null 2>&1 & wd=$!                     # stdio detached: never holds a caller's pipe open
  RC=0; wait "$pid" || RC=$?
  kill "$wd" 2>/dev/null || true; wait "$wd" 2>/dev/null || true
  [ -e "$2.timeout" ] && RC=124
  return 0
}
ROWS=()
run_one() { # $1 = raw ID
  local id block heading inp exp files pf rf jf rc line
  id="$(canon_id "$1")"
  [ -n "$id" ] || { ROWS+=("$1"$'\t'ERROR$'\t'"unknown id (see --list)"); return; }
  block="$(block_of "$id")"
  heading="$(printf '%s\n' "$block" | head -1)"
  inp="$(printf '%s\n' "$block" | sed -n 's/^- \*\*Input:\*\* //p' | head -1)"
  exp="$(printf '%s\n' "$block" | sed -n 's/^- \*\*Expected:\*\* //p' | head -1)"
  { [ -n "$inp" ] && [ -n "$exp" ]; } || { ROWS+=("$id"$'\t'ERROR$'\t'"block missing Input/Expected"); return; }
  files="$(printf '%s\n%s\n' "$heading" "$inp" | cited_files)"
  [ -n "$files" ] || files="$SKILL/SKILL.md"
  if [ "$EXTRACT" = 1 ]; then
    printf '== %s  %s\nfiles:\n%s\ninput: %s\nexpected: %s\n\n' "$id" "$heading" "$files" "$inp" "$exp"
    ROWS+=("$id"$'\t'EXTRACT$'\t'"$(printf '%s\n' "$files" | wc -l | tr -d ' ') file(s), no model calls"); return
  fi
  pf="$TMP/$id.run.prompt"; rf="$TMP/$id.run.out"; jf="$TMP/$id.judge.out"
  { while IFS= read -r f; do printf -- '---- BEGIN %s ----\n' "${f#"$SKILL/"}"; cat "$f"; printf -- '\n---- END ----\n'; done <<<"$files"
    printf '\nSCENARIO INPUT:\n%s\n\nState precisely what the skill requires the conductor/unit to do in this situation. Concrete actions and outputs only — no meta-commentary.\n' "$inp"
  } >"$pf"
  echo "[$id] run call (claude -p, timeout ${TIMEOUT_SECS}s)..." >&2
  claude_call "$pf" "$rf"; rc="$RC"
  [ "$rc" = 0 ] || { ROWS+=("$id"$'\t'ERROR$'\t'"run call rc=$rc$([ "$rc" = 124 ] && echo ' (timeout)' || true)"); return; }
  { printf 'SCENARIO EXPECTED (spec):\n%s\n\nRESPONSE UNDER TEST:\n' "$exp"; tr -d '\r' <"$rf"
    printf "\nDoes the response satisfy every load-bearing expectation? Answer EXACTLY 'PASS: <one line>' or 'FAIL: <specific miss>'.\n"
  } >"$TMP/$id.judge.prompt"
  echo "[$id] judge call..." >&2
  claude_call "$TMP/$id.judge.prompt" "$jf"; rc="$RC"
  [ "$rc" = 0 ] || { ROWS+=("$id"$'\t'ERROR$'\t'"judge call rc=$rc$([ "$rc" = 124 ] && echo ' (timeout)' || true)"); return; }
  line="$(tr -d '\r' <"$jf" | grep -m1 -E '^(PASS|FAIL):' || true)"
  case "$line" in
    PASS:*) ROWS+=("$id"$'\t'PASS$'\t'"${line#PASS: }");;
    FAIL:*) ROWS+=("$id"$'\t'FAIL$'\t'"${line#FAIL: }");;
    *)      ROWS+=("$id"$'\t'ERROR$'\t'"unparseable judge verdict (see $jf)");;
  esac
}

EXTRACT=0; IDS=()
for a in "$@"; do case "$a" in
  --list) ids_available; exit 0;;
  --extract) EXTRACT=1;;
  -h|--help) usage; exit 0;;
  *) IDS+=("$a");;
esac; done
[ "${#IDS[@]}" -gt 0 ] || { usage; exit 1; }
for i in "${IDS[@]}"; do run_one "$i"; done
printf '\n%-12s %-8s %s\n' ID RESULT NOTE
ok=0; bad=0
for r in "${ROWS[@]}"; do
  IFS=$'\t' read -r id res note <<<"$r"; printf '%-12s %-8s %s\n' "$id" "$res" "$note"
  case "$res" in PASS|EXTRACT) ok=$((ok+1));; *) bad=$((bad+1));; esac
done
echo "summary: ${#ROWS[@]} selected, $ok ok, $bad not-ok  (raw prompts/outputs: $TMP)"
[ "$bad" -eq 0 ]
