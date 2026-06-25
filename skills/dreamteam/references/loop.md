# Dreamteam — Core Engine (the per-workstream loop)

Given an approved plan + a dreamteam manifest, drive each **workstream** to a verified, integrated result. The main loop is the **conductor** — it stays visible and reports every gate verdict.

## The loop (per workstream)
```
produce   → dispatch the producer agent(s) at their manifest tier — resolve the dispatch verb + concrete model per references/platforms.md (Claude: Agent tool model:<resolved>; Gemini: @agent frontmatter model:; Codex: agent model=), with their manifest skills
gate      → review per references/gate.md (parallel panel → synthesize → verdict)
fix       → if fix-then-pass: run gate.md's capped fix loop (gate_policy.max_fix_iterations)
integrate → land the verified artifact via superpowers:finishing-a-development-branch (merge / PR / keep · then clean up the worktree)
report    → print the workstream's verdict + the evidence behind the pass
```
- **Re-anchor every workstream (mandatory).** Before producing WS-N (including the **first** producer/specialist dispatch of the run), announce: **"Dispatching `<role>` for WS-N at `<tier>` — `<background subagents | Workflow>` (session mode)."** This line is required for *every* workstream — it re-states the conductor rule and makes a missing dispatch an obvious tell (per `SKILL.md` §"You are the conductor"); the mode tag makes a foreground/inline slip as visible as a missing dispatch. (When a Workflow script drives the pipeline, the equivalent is the script's per-stage dispatch record — the requirement is that every workstream's production is a *logged dispatch*, not that you type the line by hand.) If dispatch is unavailable, say so and pause — never silently produce inline.
- **Pre-edit self-check.** Before any Edit/Write/Bash that would PRODUCE a workstream's artifact, ask: *"am I the producer for this workstream?"* If yes → STOP and dispatch. The conductor edits only to **integrate** a verified result, never to produce one.
- **Integrate only after a pass** (or a fix-then-pass that cleared). A green gate is the entry condition for landing.
- **Verify before claiming done.** Before reporting a workstream — or the whole run — complete/passing, apply REQUIRED: `superpowers:verification-before-completion` (run the checks and cite the evidence; never assume green). It is the gate's honesty rule at the conductor level.
- **needs-work** from the gate → stop, escalate, do **not** integrate and do **not** start dependents.
- **Designers** (manifest `designers[]`, when present) are scheduled as producers of the relevant design workstream — the same produce→gate→integrate loop applies. (Profiles already express design as a producer role.)
- **Dispatch each producer with an explicit, verifiable success criterion** (what the gate will check) — not "make it work." Before producing, **surface assumptions/ambiguities**; if genuinely under-specified, return **NEEDS_CONTEXT** rather than guessing (surfacing is pre-work; NEEDS_CONTEXT is its escalation).
- **Produce the simplest solution that fully works (minimal-code — dreamteam's standing principle).** Every producer applies the ladder: *does it need to exist? (YAGNI) → stdlib → native platform feature → an existing dependency → one line → the minimum that works*. Complete and correct, but no over-engineering / speculative generality — and **never** by cutting validation, security, or accessibility — and the **smallest diff that achieves it**: touch only what the task requires; don't refactor or restyle untouched code; remove only the orphans your change creates. The gate enforces this; the `ponytail` skill amplifies it when composed.

## Model tier + escalation (replicates subagent-driven-development)
Each producer is dispatched at its manifest tier and reports one status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED.
- Gate **needs-work**, fix-then-pass not clearing, or **BLOCKED (needs more reasoning)** → re-dispatch the fix/redo ONE TIER UP (cheap→standard→capable[→max only if the ceiling allows, per the cap below]), within `gate_policy.max_fix_iterations`. Never silently retry the same tier on a reasoning failure.
- **NEEDS_CONTEXT** → add the missing context, re-dispatch SAME tier.
- **Task too large** → split into smaller workstreams (don't just escalate the model).
- **Plan/spec wrong** → escalate to the human (don't burn tiers).
- Cap: escalation stops at the manifest ceiling (default capable; max only if the run/override allows) and at `max_fix_iterations` → then escalate to the human; never weaken the gate to force a pass.
- Reviewers do not auto-escalate (already at the capable default); a reviewer that errors is replaced per existing resilience.
- **Tier unavailable / not dispatchable** → fall back to the nearest available tier and flag it in the report (mirrors agent-unavailable in `SKILL.md` Resilience); never fail a workstream merely because a tier is missing.
- Report each escalation ("WS2 failed gate at standard → retrying at capable").

## Sequencing (from `workstream_strategy`)
- **`sequential`** — run workstreams in plan order; a dependent workstream waits for its predecessor to integrate.
- **`parallel`** — run independent workstreams concurrently (e.g. ai-research *expand* ∥ *polish*). Only parallelize workstreams with no shared inputs/outputs.

## Producer isolation (parallel work)
A producer that **mutates files** while other producers — or the conductor prepping the next workstream — run concurrently **gets its own git worktree**. REQUIRED: `superpowers:using-git-worktrees`. On a passing gate, land and clean up the worktree via `superpowers:finishing-a-development-branch`.
> Lesson from the build this skill generalizes: a producer and the conductor sharing **one** working tree forced everything to serialize. Separate worktrees = real parallelism without collision.

Read-only work needs no worktree. Verifying reviewers that contend for a build resource follow the same isolation rule (`gate.md` §1).

## Audit (read-only review/audit runs)
When the run is an `audit` profile, the loop still applies but **`integrate` is a no-op** — the report **is** the artifact. A `needs-work` finding is **dropped from the report** (the issue it names is omitted), not cause to discard the whole deliverable. Audit producers are read-only, so they take **no worktree** (per §"Producer isolation" above — same rule, not a new one). Even read-only finding-emitters are **dispatched subagents**: the conductor **never "just looks"** at the code and reports inline — that would reintroduce the un-gated self-review the dispatch rule exists to prevent. See `references/audit.md` for the audit modes, `--depth`, and crew detail.

## Setup (opt-in pre-flight install)
On a human-**approved** recommendation (per `references/recommend.md`), the conductor dispatches a `setup` producer **before** the main crew → the gate verifies presence + identity/source + that the dispatched install command was the pinned approved one (no `-y`) → on PASS the conductor **re-casts** (re-enters precedence) so the now-installed skill attaches (re-cast at most once per approved set; a re-cast must not generate a new recommendation for the same set) → FAIL → escalate, proceed with best-available. Reuses produce→gate→integrate; no new gate machinery. The Caster only recommends — **discovery in, advice out**; the `setup` producer installs, never the conductor inline.

## Driving the loop: conductor vs Workflow tool
- **Dispatch is always background — never inline/foreground in the main chat.** Producers/reviewers run detached (on Claude Code: the Agent tool's background dispatch / `run_in_background`); the conductor does NOT hand-fire blocking foreground Agent calls inline (the repeated drift this guards against). Background dispatch is non-blocking-in-chat, **NOT** fire-and-forget: the conductor still **awaits each producer's result, then gates it** (`gate.md`). The sequence dispatch→await→gate→integrate is unchanged.
- **Execution mode — chosen once per session (default background).** On the **first producer/specialist dispatch of the run**, ask the user once: "Background subagents or the Workflow tool? [background]". Use that answer for **every dispatch this SESSION**; surface it in the first re-anchor line. No answer → **background subagents**. Ask **only once**; best-effort across the session (if the choice isn't in view later, re-ask rather than assume) — never re-prompt per workstream. **When `--execution <mode>` is given on invocation, it PRE-SETS the session mode and SKIPS this prompt** — the flag IS the answer (`background` = background subagents; `workflow` = the Workflow tool, Claude-Code-only per `platforms.md`); still surface the chosen mode in the first re-anchor line. With no flag, ask as today. This only pre-sets the one-time session choice — dispatch stays always-background and there is no per-workstream re-prompt.
- **The Workflow tool (Claude Code only).** On Claude Code the deterministic `produce → gate → fix` pipeline MAY instead be a `Workflow` script (pipeline/parallel stages, a worktree per file-mutating producer) — itself a background orchestration engine; prefer it for many independent workstreams. On Codex/Gemini/CodeWhale there is no Workflow tool → background subagents always, no prompt (`platforms.md`).
- Either way the conductor **reports each workstream's gate verdict** — orchestration never hides a gate.

## Report
Per workstream: the verdict (pass / fix-then-pass / needs-work), what was fixed, the **evidence** behind the pass, and what was integrated (commit / branch / artifact); when escalation occurred, the **tier path** (e.g. standard→capable). Pause only for genuine decisions or a needs-work escalation. End the run with the retro's learnings summary + any proposed skill-edit deltas (awaiting approval).

## Retro (run end)
After all workstreams integrate, run the retro when `--retro` is on (the default): `references/retro.md` over the run record (the §Report buffer — per-workstream verdicts + escalation tier-paths + fix counts) → persist learnings to `references/learnings.md` → surface any proposed skill-edit deltas for human approval. **Skill edits are never auto-applied.** (`--evolve` additionally opts an ai-research run into the Layer-B generations loop, `references/evolve.md`.)
