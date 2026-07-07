#!/usr/bin/env node
'use strict';
/*
 * dreamteam-compact-rearm.js — Claude Code SessionStart hook (matcher: compact).
 *
 * ADVISORY-ONLY, DEFAULT ON, FAIL-OPEN. After a compaction the conductor's
 * context reopens with a summary — dreamteam's skill rules survive only as that
 * summary and behavior drifts back toward default. This hook injects ONE
 * conditional line telling the model to re-hydrate from disk (the compaction
 * re-arm, SKILL.md §Resilience). It never blocks, never denies, and emits
 * nothing on any error or when silenced.
 *
 * API verified against https://code.claude.com/docs/en/hooks :
 *   - SessionStart matcher values: startup | resume | clear | compact
 *   - stdin payload carries a "source" field ("startup"|"resume"|"clear"|"compact")
 *   - context is added via
 *     {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"…"}}
 *     printed to stdout with exit 0
 *
 * Posture — deliberately the OPPOSITE of dreamteam-run-policy.js: that hook can
 * DENY tool calls, so it is opt-in (DREAMTEAM_ENFORCE=1); this one only adds one
 * line of context, only on compact events, so it is DEFAULT ON and opt-OUT via
 * DREAMTEAM_NO_COMPACT_REMINDER=1. Fail-open by construction: any parse/IO/
 * unexpected error → exit 0 with NO output.
 */

var fs = require('fs');

function silent() { process.exit(0); }                // no output => nothing injected

function main() {
  // ---- opt-OUT gate (the hook is ON by default) ----
  if (/^(1|true|on|yes)$/i.test(String(process.env.DREAMTEAM_NO_COMPACT_REMINDER || ''))) return silent();

  // ---- read + parse the hook payload from stdin (fail-open on any hiccup) ----
  var raw = '';
  try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { return silent(); }
  var input;
  try { input = JSON.parse(raw || '{}'); } catch (_) { return silent(); }
  if (!input || typeof input !== 'object') return silent();

  // hooks.json already matches "compact"; re-check defensively — advisory means
  // never firing off-event (startup/resume/clear stay untouched).
  if (String(input.source || '') !== 'compact') return silent();

  try {
    // fs.writeSync(1, ...) guarantees a synchronous flush to stdout before exit.
    fs.writeSync(1, JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: 'A compaction just occurred. If a dreamteam run or session-stickiness was active, re-read the dreamteam SKILL.md from disk and re-anchor before the next artifact task.'
      }
    }));
  } catch (_) { /* cannot emit => stay silent (advisory, never an error) */ }
  process.exit(0);
}

// Belt-and-suspenders: any unforeseen throw => silent exit 0 (never disturb the session).
try { main(); } catch (_) { silent(); }
