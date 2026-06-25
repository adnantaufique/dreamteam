# Dreamteam — Retro (Layer A: learn from the run)

After a run, the conductor learns from what actually happened — adapting SIA's self-improvement loop to dreamteam.

**SIA → dreamteam mapping:** meta-agent ≈ Caster/planner · target-agent ≈ producers · feedback-agent ≈ this retro reviewer · evaluator ≈ the gate.

## The run record (what the retro reads)
The **run record** is the conductor's per-run **report buffer** — the same per-workstream verdicts, must-fixes, escalation tier-paths, and fix-iteration counts the loop already prints (`loop.md` §Report). The retro consumes that buffer; it does **not** require a new persisted artifact.

## The retro procedure
At run end (when `--retro` is on — the default), the conductor dispatches a **feedback** reviewer with the run record:
- per-workstream gate verdicts + must-fixes + the **evidence** behind each pass;
- **escalations** — which roles hit BLOCKED/needs-work and what tier finally cleared them (from F1's reported tier path);
- fix-iteration counts; agent/tier substitutions; first-try misses.

The feedback reviewer emits a **learnings record** (schema below), which is appended to `references/learnings.md`.

## Learnings schema
```
{ run_id, profile, task_kind,
  worked: [ <evidence-backed observation> ],
  change: [ { target: profile|caster|tier|gate, delta: <concrete>, evidence: <why> } ],
  confidence: low|med|high }
```
(`task_kind` is a short free-text kind tag, e.g. "leak-prone build" or "load-test"; `profile` is the primary match key and `task_kind` is matched loosely alongside it.)

## Human gate + honesty
- Any change whose `target` would **edit the skill itself** (profiles.md tiers, caster heuristics, gate policy) is **PROPOSED, not auto-applied** — the conductor surfaces the deltas; the human approves. Auto-persisted entries in the store (`references/learnings.md`) are **advisory defaults** the Caster can override, never hard rules.
- **No learning without a run that supports it** — the feedback agent must cite the run evidence for every `change` (ties to `gate.md` §3, the honesty rule). A learning with no evidence is dropped, not recorded.
