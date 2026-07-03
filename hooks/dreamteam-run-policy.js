#!/usr/bin/env node
'use strict';
/*
 * dreamteam-run-policy.js — Claude Code PreToolUse hook.
 *
 * A THIN, OPT-IN, FAIL-OPEN harness-level backstop that sits *under* dreamteam's
 * prose run_policy guards (references/caster.md) and the leaf firewall
 * (SKILL.md <SUBAGENT-STOP>). It never replaces them — it hardens two points on
 * Claude Code, where PreToolUse hooks were measured to fire live in-session AND
 * inside dispatched subagents.
 *
 * Ground truth (measured this session with a live PreToolUse logging hook):
 *   - Hooks fire in the main session (agent_id === null) AND inside subagents
 *     (agent_id === a non-null string). => a hook CAN tell a leaf from the conductor.
 *   - The dispatch tool on this harness is "Agent" (older/other harnesses: "Task").
 *   - session_id is NOT reliable for run-scoping (some subagents share the main
 *     session_id, others get their own) => leaf-detection keys on agent_id, and the
 *     dispatch counter keys on a per-run marker (cwd + a /dreamteam reset), NOT session_id.
 *   - A deny is the documented shape on stdout with exit 0.
 *
 * Enforcement is OFF unless DREAMTEAM_ENFORCE is truthy (1|true|on|yes). An
 * unenabled user is never touched. When ENABLED:
 *   (a) LEAF-DENY  — a dispatched leaf (agent_id present) that calls a dispatch tool
 *                    (Agent/Task) or re-invokes /dreamteam (Skill=dreamteam) is denied.
 *                    This is the recursion firewall, now a real mechanical block.
 *   (b) DISPATCH CAP — main-session (agent_id null) Agent/Task dispatches are counted
 *                    per run and denied over the hook's OWN threshold
 *                    (DREAMTEAM_MAX_TOTAL_DISPATCHES, default 60) — a fixed second layer
 *                    that never reads the capacity-resolved run_policy.max_total_dispatches
 *                    (set the env knob to align it with a lower capacity row) — with a
 *                    "STOP and escalate to the human" reason.
 *
 * FAIL-OPEN by construction: any parse/IO/unexpected error, or the opt-in being off,
 * exits 0 with NO output = normal permission flow (allow). A backstop must NEVER be the
 * reason a legitimate tool call is blocked. The hook only ever stays silent (allow) or
 * prints exactly one "deny"; it never prints an "allow" decision (never force-allows).
 */

var fs = require('fs');
var os = require('os');
var path = require('path');
var crypto = require('crypto');

function allow() { process.exit(0); }                 // silent => normal permission flow

function deny(reason) {
  try {
    // fs.writeSync(1, ...) guarantees a synchronous flush to stdout before exit.
    fs.writeSync(1, JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: reason
      }
    }));
  } catch (_) { /* if we cannot even emit the deny, fall through to allow */ }
  process.exit(0);
}

function posInt(v, d) { var n = parseInt(v, 10); return (isFinite(n) && n > 0) ? n : d; }

function readState(file) {
  try {
    var s = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (s && typeof s === 'object' && typeof s.count === 'number') return s;
  } catch (_) {}
  return null;
}

function writeState(file, s) {
  try { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, JSON.stringify(s)); } catch (_) {}
}

function main() {
  // ---- opt-in gate: OFF by default ----
  if (!/^(1|true|on|yes)$/i.test(String(process.env.DREAMTEAM_ENFORCE || ''))) return allow();

  // ---- read + parse the hook payload from stdin (fail-open on any hiccup) ----
  var raw = '';
  try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { return allow(); }
  var input;
  try { input = JSON.parse(raw || '{}'); } catch (_) { return allow(); }
  if (!input || typeof input !== 'object') return allow();

  var agentId = input.agent_id;                       // null/undefined = main session; string = a dispatched leaf
  var isLeaf  = agentId !== null && agentId !== undefined && String(agentId).length > 0;
  var tool    = String(input.tool_name || '');
  var ti      = (input.tool_input && typeof input.tool_input === 'object') ? input.tool_input : {};
  var cwd     = String(input.cwd || 'no-cwd');

  var isDispatch = /^(Agent|Task)$/i.test(tool);      // dispatch tool = Agent (this harness); Task defensively
  var isSkill    = /^Skill$/i.test(tool);
  // Skill identity lives in a name-ish field; match dreamteam without slurping arbitrary args.
  var skillId = [ti.skill, ti.name, ti.skill_name, ti.command]
    .map(function (x) { return String(x == null ? '' : x).toLowerCase(); }).join(' ');
  var isDreamteamSkill = isSkill && skillId.indexOf('dreamteam') !== -1;

  // ============================================================ (a) LEAF-DENY
  // A dispatched leaf must never dispatch/orchestrate or re-invoke /dreamteam — the
  // recursion firewall (run_policy.max_depth=1). Not run-scoped: a leaf cannot reliably
  // correlate to its parent run (session_id is unreliable across subagents), but it CAN
  // know it is a leaf (agent_id present) — which is all this rule needs.
  if (isLeaf) {
    if (isDispatch) {
      return deny('dreamteam recursion firewall: a dreamteam leaf (agent_id=' + agentId +
        ') must not dispatch or orchestrate further subagents. Do only your one briefed task and return its result. ' +
        '(run_policy.max_depth=1; SKILL.md <SUBAGENT-STOP>)');
    }
    if (isDreamteamSkill) {
      return deny('dreamteam recursion firewall: a dreamteam leaf (agent_id=' + agentId +
        ') must not re-invoke /dreamteam or act as a conductor. Do only your one briefed task and return. ' +
        '(SKILL.md <SUBAGENT-STOP>)');
    }
    return allow();                                   // a leaf's normal briefed tool/skill use is fine
  }

  // ============================================================ main session only past here
  // Only the conductor's own dispatches and the top-level /dreamteam arming call matter here.
  if (!isDispatch && !isDreamteamSkill) return allow();

  var MAX_TOTAL = posInt(process.env.DREAMTEAM_MAX_TOTAL_DISPATCHES, 60);
  var TTL_MS    = posInt(process.env.DREAMTEAM_RUN_TTL_MS, 12 * 60 * 60 * 1000); // stale-run auto-reset
  var dir  = path.join(os.tmpdir(), 'dreamteam-hooks');
  var key  = crypto.createHash('sha1').update(cwd).digest('hex').slice(0, 16);   // per-run marker key: cwd, NOT session_id
  var file = path.join(dir, 'run-' + key + '.json');
  var now  = Date.now();

  var st = readState(file);
  if (st && (now - (st.started || 0)) > TTL_MS) st = null;                        // stale => treat as a fresh run

  // Per-run marker: a top-level /dreamteam Skill call (main session) starts/resets the run
  // budget and ARMS the cap. Each /dreamteam gets its own fresh 60.
  if (isDreamteamSkill) { writeState(file, { started: now, count: 0, dt: true }); return allow(); }

  // A main-session dispatch. With no armed run seen, count but never deny (fail-open: the cap
  // only bites inside a detected dreamteam run, so an unrelated main session is never blocked).
  if (!st) st = { started: now, count: 0, dt: false };
  var next = (st.count || 0) + 1;

  // ============================================================ (b) DISPATCH CAP
  if (st.dt && next > MAX_TOTAL) {
    // Do NOT persist the over-cap increment: the block is idempotent, and raising the env cap
    // (or a fresh /dreamteam) lets the very next call through.
    return deny('dreamteam run_policy.max_total_dispatches reached (' + MAX_TOTAL +
      ' dispatches this run). STOP and escalate to the human — do not silently continue. ' +
      'To proceed on a known-large, human-approved run, re-invoke /dreamteam for a fresh budget ' +
      'or raise DREAMTEAM_MAX_TOTAL_DISPATCHES.');
  }

  st.count = next;
  writeState(file, st);
  return allow();
}

// Belt-and-suspenders: any unforeseen throw => allow (never block real work).
try { main(); } catch (_) { allow(); }
