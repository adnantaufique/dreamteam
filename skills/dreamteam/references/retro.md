# Dreamteam — Retro (Layer A: learn from the run)

After a run, the conductor learns from what actually happened — adapting SIA's self-improvement loop to dreamteam.

**SIA → dreamteam mapping:** meta-agent ≈ Caster/planner · target-agent ≈ producers · feedback-agent ≈ this retro reviewer · evaluator ≈ the gate.

## The run record (what the retro reads)
The **run record** is the conductor's per-run **report buffer** — the same per-workstream verdicts, must-fixes, escalation tier-paths, and fix-iteration counts, and the decision log and dispatch-reliability record the loop already prints (`loop.md` §Report), plus each producer's **skill-usage line** (which attached skills were used, to what effect — `loop.md` §"Model tier + escalation"). The retro consumes that buffer; it does **not** require a new persisted artifact.

## The retro procedure
At run end (when `--retro` is on — the default), the conductor dispatches a **feedback** reviewer with the run record (except a **micro-scale** run — the conductor appends the learnings line itself, no feedback-agent dispatch, `loop.md` §Retro; the evidence rule below governs either way):
- per-workstream gate verdicts + must-fixes + the **evidence** behind each pass;
- **escalations** — which roles hit BLOCKED/needs-work and what tier finally cleared them (from F1's reported tier path);
- fix-iteration counts; agent/tier substitutions; first-try misses;
- **dispatch reliability** (`loop.md` §Report) — per role: drops by failure class (dropped-without-returning vs returned-but-inadmissible), recovery re-dispatches, schema-cap schema-free re-runs, refuter outcomes (refuted-and-dropped vs stood), and **per-role wall-clock durations (median + max)**. The feedback reviewer may cite these counts as run evidence for a learning — a role that repeatedly drops, a reviewer whose predictions are repeatedly refuted, or a role that dominates the run's wall-clock, is itself an evidence-backed learning.
- **skill usage** (`loop.md` §"Model tier + escalation") — per producer: which attached skills were actually USED vs unused, and the cited effect. The Caster attaches `producers[].skills` blind otherwise — this is the feedback that lets attachment decisions improve. The feedback reviewer MAY emit a skill-attachment learning from it — a row in the **LEARNINGS table (`references/learnings.md`), never the agent scouting ledger** (usage advice is prose, not counts): e.g. *"task_kind X: `ponytail` attached but unused across 3 runs"*, or *"`karpathy-guidelines` cited as shaping the diff"*. Same evidence rule, same `confidence` mechanics as any learning — advisory for the next cast's attachment call (`references/caster.md` step 0), **never enforcement: a learning never auto-detaches a skill**.

The feedback reviewer emits a **learnings record** (schema below), which is appended to `references/learnings.md`.

It also **updates the agent scouting ledger** (`references/learnings.md`): map the **run record** (`loop.md` §Report buffer, including the dispatch-reliability tally) to the **agents that filled those roles** (the manifest names them; **refuter outcomes are already keyed to the emitting reviewer**, so no re-derivation is needed) and **append — or increment the counts of — the matching ledger rows** (same agent + `project_key` + `profile`). **No row without run evidence** — the honesty rule below applies to ledger rows exactly as to learnings. The **human gate is unchanged**: ledger rows are auto-persisted **advisory data**, like learnings-store entries — never skill edits.

## Learnings schema
```
{ run_id, project_key, profile, task_kind,
  worked: [ <evidence-backed observation> ],
  change: [ { target: profile|caster|tier|gate, delta: <concrete>, evidence: <why> } ],
  confidence: 0.3–0.9 }
```
- **`project_key`** — a stable hash of the repo's **git remote (origin) URL** (the same project matches across clones); it **scopes** the learning to the project it came from, so a learning from project A no longer leaks into project B. A repo with **no remote** (or a deliberately cross-project insight) is stamped **`global`** (consulted on every run). See the project-vs-global split + the optional project→global promotion in `references/learnings.md`.
- **`profile`** stays the **primary match key**; **`task_kind`** (a short free-text kind tag, e.g. "leak-prone build" or "load-test") is matched **loosely alongside it** (unchanged).
- **`confidence`** is now **numeric `0.3–0.9`** (replacing `low|med|high`) so corroboration moves it in small steps:
  - **Start** at **0.3–0.5** for a single-run observation (more direct run evidence → higher in the band).
  - **Increase → up to 0.9:** each **later run that corroborates** the same learning (same `profile`/`task_kind`, consistent evidence), or a change that **measurably** improved the outcome (gate cleared faster · fewer fix-iterations · fewer first-try misses). **Cap 0.9** — never 1.0, since a learning is an **overridable advisory default**, never a hard rule.
  - **Decrease → down to 0.3:** a **later run that contradicts** it (the default produced a worse roster/tier/gate outcome, or a human override beat it) or staleness. **Floor 0.3** — **below 0.3 the entry is dropped, not stored** (ties to the evidence rule below: no supporting run evidence → not recorded).

## Human gate + honesty
- Any change whose `target` would **edit the skill itself** (profiles.md tiers, caster heuristics, gate policy) is **PROPOSED, not auto-applied** — the conductor surfaces the deltas; the human approves. Auto-persisted entries in the store (`references/learnings.md`) are **advisory defaults** the Caster can override, never hard rules.
- **No learning without a run that supports it** — the feedback agent must cite the run evidence for every `change` (ties to `gate.md` §3, the honesty rule). A learning with no evidence is dropped, not recorded.
