# Dreamteam — Audit (the `audit` profile: read-only review subsystem)

A profile that runs an **ultrareview-style audit locally via dreamteam's crew** — it replicates the *methodology* (fan out specialists → confirm findings against evidence → emit a report), not the cloud sandbox. Prior art: **`/code-review ultra`** (alias **`/ultrareview`**), a research-preview that runs in a cloud sandbox; the `map` mode below is dreamteam's own extension. The `audit` profile **reuses `loop.md`'s fan-out + the `gate.md` verdict/reconciliation machinery — there is no new review engine.**

## Invariant — read-only (state up top)
- **The report *is* the artifact.** The `audit` profile produces a report; it does **not** change the code under audit.
- **`integrate` is a no-op.** Nothing lands in the audited tree; the loop's `integrate` step just emits/keeps the report. A green run = a delivered report, not a merge.
- **A `needs-work` finding is dropped from the report** — it does NOT discard the whole deliverable. A finding that can't be confirmed is simply not listed; the surviving report still ships.
- **Read-only producers need no worktree** — they only read (`loop.md` §Producer isolation already states this; not restated here). A reproducer that *runs a build* is the exception — see the fan-out cap.
- **Even read-only finding-emitters are dispatched subagents.** The conductor **never "just looks" and reports inline** — that would skip the gate (per `SKILL.md` §"You are the conductor"). Every dimension/area specialist is a dispatched producer; the conductor only synthesizes + reports.

## Two modes (`--mode`, default `bugs`)
### `bugs` (default) — confirmed-bug hunt
- Fan out **dimension specialists as *producers*** — correctness, security, performance, concurrency, error-handling, resource-leaks, API-contract.
- Each emits **candidate findings** `{file:line, dimension, severity, evidence}`.
- The **gate** dedups (`gate.md` §2) and the **Reality Checker reproduces/refutes** each candidate (`gate.md` §3 — evidence beats prediction; an unreproduced finding is dropped).
- **Output = the surviving *confirmed* bug list** (the role `bugs.json` plays in ultrareview).

### `map` — project mental-model
- Fan out **module/area specialists as producers**: **Explore** for read-only structure; **Software Architect** / **system-architect** for architecture + data-flow — plus a **synthesizer** producer that merges their outputs.
- **Output = a structured mental-model**: architecture, module inventory, data flow, dependencies, risk hotspots.

## `--depth shallow | module | exhaustive` (default `module`)
Tunes fan-out **breadth** + the specialist **tiers**. `exhaustive` is **budget-printed + confirm-gated** before it runs (same guardrail as `--evolve`, `evolve.md`) — print the projected fan-out/cost and wait for the user's OK.

## Fan-out cap
Reads **`audit_policy.max_parallel_reviewers`** (the `caster.md` manifest field — a top-level sibling of `gate_policy`, not nested in it). Per-depth defaults:

| depth | default max_parallel_reviewers |
|---|---|
| shallow | 2 |
| module | 4 |
| exhaustive | 8 |

- **Global ceiling: 12** — no depth/override pushes concurrent specialists past it.
- Any **build-running reproducer** obeys `gate.md` §1's resource-isolation rule (don't run two contending verifiers on one build resource — serialize or sandbox each).
- The single **devil's-advocate** reviewer (when the `audit` gate turns it on) runs **after** consensus and **outside** the fan-out — it does **not** count against this cap.

## Crew availability
The audit fan-out resolves through the **same availability gate as any profile** (`caster.md` precedence): a missing dimension specialist is **substituted or flagged by the Caster**, never assumed installed. No dimension is silently skipped because its specialist is absent.

## Reuse, don't rebuild
The `audit` profile is a thin layer over the existing engine — `loop.md` fan-out + `gate.md` verdict/reconciliation. The only `audit`-specific gate posture is a set of **gate extensions the `audit` gate turns on by default**:
- **F9's mutation / mock-integrity clauses** (`gate.md` §3 — a passing test must go red on a broken impl; mocks don't stand in for the unit) are applied as the default audit posture, not an afterthought.
- **Devil's-advocate on unanimous** — `gate_policy.devils_advocate_on_unanimous: true` (the one profile that defaults it on; fires only when the panel meets `devils_advocate_min_panel`, default 3).

> No new verdict logic, no second review pipeline — the `audit` gate is the standard gate with these toggles flipped on.
