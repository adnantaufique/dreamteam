---
name: dreamteam
description: Use when a multi-step task or an approved plan should be driven to a verified, independently-reviewed result by orchestrating specialist agents across domains (software builds, ML/CV research, devops, QA) — when one task needs several specialists, when you want review gates between steps instead of one unreviewed dump, or when you have a plan to execute with quality checkpoints.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent for a dreamteam run — a producer, reviewer,
planner, designer, Caster, or setup agent — you are a **LEAF**. Do only the one
task in your dispatch brief and return. Do **NOT** invoke `/dreamteam`, do **NOT**
act as the conductor, do **NOT** orchestrate, and do **NOT** spawn any further
subagents or Workflow scripts. The "You are the conductor" and "Session stickiness"
rules below bind ONLY the conductor / main session — they never apply to you.
Follow your brief, not the rest of this skill.
</SUBAGENT-STOP>

# Dreamteam

## Overview

Orchestrate a task (or an approved plan) to a *verified* result. A **Caster** selects a dreamteam of specialist agents for the task; each unit of work runs **produce → gate (independent review) → fix → integrate**. The main loop stays the visible conductor — every gate verdict is reported. Domain-agnostic: the loop is constant, only the dreamteam changes.

For **builds**, dreamteam is spec-driven by default — the wrapper turns a raw idea into a reviewed plan, and each workstream is dispatched with a verifiable success criterion the gate then enforces. Non-build sweeps (audit, qa) skip the spec. The constant is verification, not the spec.

**Standing principles** (native to dreamteam — they hold on every run): (1) **honest** — the gate backs every claim with evidence and the Reality Checker is always on the panel; (2) **minimal-code** — producers ship the *simplest solution that fully works* (no over-engineering or speculative generality), kept complete and correct, and **never** by cutting validation, security, or accessibility; for code producers this is composed-enforced by `ponytail` + `karpathy-guidelines` when installed (see Composes); (3) **objective** — every assessment states the unvarnished verdict: no sugar-coating, no over-praise, no softening a failure toward a pass. This governs the *tone* of an assessment (don't glaze), and is distinct from (1)'s *evidence* requirement (don't claim without proof).

Runs on Claude Code, Codex CLI, Gemini CLI, CodeWhale, and OpenCode — tool names, subagent dispatch, and model tiers resolve per `references/platforms.md` (`--platform` defaults to auto-detect).

**Opt-in:** this runs multi-agent orchestration only when explicitly invoked (`/dreamteam …`). This is an **invocation gate on the conductor** entering orchestration — it is **NOT** a leaf/auto-load guard. A subagent whose context auto-loads this skill by description-match is stopped by the `<SUBAGENT-STOP>` block above (identity, read first), not by this line.

## You are the conductor
**You are the conductor — you do NOT produce workstreams yourself.** Every workstream's artifact is produced by a **dispatched producer subagent**. You may ONLY: resolve the crew, **dispatch** producers/reviewers, synthesize gate findings, **integrate** a *verified* result (merge/commit/land), and report. You may read files for orchestration. You may **NOT** write code, edit files, or run builds/experiments to *produce* a workstream's artifact — that is the producer's job, and doing it yourself skips the independent gate. **When you synthesize and report, do so objectively — no glazing:** state each gate verdict plainly and never soften a fix-then-pass or needs-work into something rosier than the evidence supports (the standing **objective** principle, applied to your own synthesis). **When you integrate, write each commit for an outside reader** — a conventional-commit subject describing *what changed* (plus the *why* when useful), **never** dreamteam's internal labels (no build-phase names like `Phase A`, no plan/checklist IDs, no workstream numbers); the standard + self-check live in `references/loop.md` §"Commit-message standard".

**Dreamteam runs at depth 1 — conductor → leaves, one level.** There is no legal depth ≥ 2: a dispatched leaf never orchestrates (`<SUBAGENT-STOP>` above), so depth is **structurally bounded by identity, not counter-tracked** — no shared depth counter across the call tree is needed or kept (`run_policy.max_depth: 1` in `references/caster.md` states the invariant).

| Conductor MAY | Conductor MUST NOT |
|---|---|
| read files/plan for orchestration; dispatch producers + reviewers; synthesize gate findings; run the capped fix loop (by re-dispatching); integrate a *verified* branch/commit; report verdicts | write/edit code or docs **to produce** a workstream's artifact; run builds/experiments **to produce** a workstream's artifact; "quick-fix" a gate finding itself instead of re-dispatching the producer |

### Red flags — STOP and dispatch
If you catch yourself thinking any of these, STOP — you are about to drift inline:

| Rationalization | Reality |
|---|---|
| "This workstream is trivial / a one-liner — I'll just do it inline." | Trivial work still needs the independent gate. Dispatch it. (Observed verbatim drift: *"it's a one-liner … not worth dispatching for … small/simple/quick enough to just handle directly."*) |
| "Dispatching is overhead; faster to edit directly." | The cost is the point — independent production + review is what 'verified' means. |
| "I already know the fix." | Then the producer will too — and the gate confirms it. You knowing ≠ verified. |
| "The subagent would just do what I'd do." | The gate reviews the *producer's* output independently; you reviewing your own work isn't a gate. |
| "I'm mid-run, easier to keep going inline." | Mid-run is exactly when the directive decays — re-anchor and dispatch. |
| "I'll just fire this Agent call foreground/inline real quick." | Foreground-inline dispatch is the inline drift this rule forbids — it blocks the chat and skips background orchestration. Dispatch in the **background** (per loop.md). |
| "It's tiny / non-workstream, so the stickiness carve-out lets me inline it." | Only if it passes ALL carve-out bounds AND isn't a workstream; in doubt → dispatch. Not a reopening of "it's a one-liner." |
| "Dispatch isn't available here, so I'll just produce it myself." | **Say so and pause → escalate to the human** — surface that orchestration is unavailable; do NOT silently substitute self-authored, un-gated work for an orchestrated result. |

**Editing a file to produce a workstream — *or* dispatching producers foreground/inline in the main chat — violates the letter AND the spirit of dreamteam. STOP and dispatch in the background.**

## Session stickiness
**This rule binds ONLY the conductor / main session — NEVER a dispatched subagent.** A dispatched unit (producer, reviewer, planner, designer, Caster, setup) is a LEAF: session stickiness never applies to it — it does its one briefed task and returns (see the `<SUBAGENT-STOP>` block at the top of this skill). A leaf has its *own* conversation with no shared store telling it the parent already owns orchestration, so the scope is stated here explicitly to close that inheritance at the source, not only at the leaf's entry.

**Once `/dreamteam` is invoked in a session, every subsequent task that produces/changes an artifact runs through dreamteam** — this extends "don't drift inline *mid-run*" to "stay in dreamteam-mode *all session*." Don't silently revert to inline on the next task.

**Session-scoped + best-effort:** the mode holds for the rest of the SESSION (across runs), tracked as conversation state — the skill is stateless, so there is no persisted store. *Best-effort:* if the decision/opt-out has fallen out of context, RE-state or RE-ask rather than assume; it is not a hard guarantee over a very long session.

**Scope:** governs tasks that **produce/change an artifact** (code/files/builds/experiments/audit deliverables). Pure Q&A, explanations, code-reading, design discussion → **answer directly** (no artifact → no workstream → nothing to gate). In a mixed "explain then change" ask, only the change is in scope.

**Opt-out (per-session, user-explicit):** "don't use dreamteam for this / do this one directly" → run ONE task outside dreamteam, then stickiness resumes; "stop using dreamteam this session" → off for the rest of the session, and a later `/dreamteam` re-arms it. **Only an explicit user statement opts out** — a task *looking* small is never opt-out (that's the carve-out). Ambiguous "skip dreamteam" → default to the narrower per-task scope.

**Carve-out — genuinely tiny, non-workstream edits:** a *direct user ask* that is NOT a workstream MAY be done inline **only if ALL hold**: not part of the current/last plan or build; **≲5 lines in one existing file**; no new logic/control-flow/files/dependencies/interface changes; nothing touching validation, security, or accessibility (examples: typo, copy/string tweak, version/constant bump, comment). **Any condition in doubt → it's not tiny → dispatch.** **State the carve-out classification visibly** before acting (auditable, not silent). This is a **narrow exception that weakens the otherwise-absolute "dispatch trivial work too" rule** — once an edit is part of a plan/build, or you'd invoke dreamteam for it, it's a workstream and the §"You are the conductor" **red flags govern, not this carve-out**.

## When to use
- A task needs more than one specialist (e.g. design + build + review).
- You want independent quality gates between steps, not one big unreviewed result.
- You have an approved plan to execute with checkpoints.
- Across domains: app builds, ML/CV research salvage, infra changes, QA sweeps.

**Not for:** a single-step task one agent handles; trivial edits; work the user hasn't asked to orchestrate.

## Invocation
```
/dreamteam <task | plan-ref>
      [--profile mobile-dev|web|ai-research|devops|qa|generic|audit|ml-dev|debug|ux-designer|tutor]
      [--depth shallow|module|exhaustive] [--mode bugs|map] [--graph on|off|auto]
      [--roster planner=…,producers=…,reviewers=…]
      [--skills a,b] [--autonomy auto|confirm|step]
      [--models planner=…,producers=<role>:<tier>;…,reviewers=<tier>] [--cost cheap|balanced|quality] [--full-gate]
      [--platform claude|codex|gemini|codewhale|opencode] [--execution background|workflow] [--repo <path>] [--branch <name>] [--parallel]
      [--retro on|off] [--learnings <path>] [--evolve [generations=N]]
```

**Flags:** `--models` sets model tiers per role; `--cost` biases the rubric (default balanced). Tiers are abstract — `cheap|standard|capable|max` — resolved to a concrete model per platform (Claude: haiku|sonnet|opus|fable) via `references/platforms.md`. `--retro` (default on) runs the end-of-run retro (`references/retro.md`); `--learnings` overrides the store path; `--evolve` opts into Layer-B benchmark evolution (`references/evolve.md`; ai-research; requires an evaluator + ground truth; budget-printed; human-gated). `--depth`/`--mode` apply to the `audit` profile (`references/audit.md`): `--mode` defaults `bugs` (read-only bug-finding) vs `map` (project map); `--depth` is `shallow|module|exhaustive`, where `exhaustive` is budget-printed + confirm-gated. `--execution background|workflow` pre-sets the per-session execution mode (skipping the one-time prompt; see `references/loop.md`) — `workflow` is Claude-Code-only and on other CLIs falls back to background subagents (`references/platforms.md`). `--graph on|off|auto` (default `auto`) toggles the optional AST code-graph (`graphify`) the conductor keeps as navigation infra: `auto` builds/reuses it when `graphify` is installed and the repo isn't oversized — else skips silently; `off` disables it; `on` requests it (still skip-if-absent, never auto-installed). The graph is **conductor infra — never a gated workstream and never a verdict**; any graph-derived claim that would gate a workstream is verified against live code/tests (`references/loop.md` §Graph, `references/audit.md`). Recommendations are advisory + default-on (surfaced only on a real capability gap); installing one is opt-in + human-gated (reuses `--autonomy`; `auto` never auto-installs). **Risk-proportional gating is default-on** (`gate_policy.risk_scaling`, `references/caster.md`): each workstream's gate panel scales with its risk class — low → the Reality Checker alone · standard → + the most relevant domain reviewer · high → the full panel — and `--full-gate` is the off-switch (`risk_scaling: off`: the full panel on every workstream), touching nothing else. **Run-level safety is default-on (no flag needed):** `run_policy` (`references/caster.md`) caps the run's breadth (`max_concurrent_agents`) and cumulative dispatches (`max_total_dispatches` → STOP + escalate on reaching it), and forces a budget-print + confirm-gate on a large projected fan-out (`budget_confirm_at`) — even under `--autonomy auto`.

## The spine
1. **Resolve the dreamteam.** REQUIRED: follow `references/caster.md` (explicit `--roster/--profile/--skills` → use as-is; else profile match; else dispatch a Caster agent). Print the dreamteam + one line of rationale per pick — including each role's model tier (cheapest-that-fits per `references/caster.md`), printed next to each pick — show the abstract tier and the resolved concrete model for the active platform (e.g. standard → sonnet).
2. **Pick the entry.** A plan-ref (a path to / inline copy of an already-reviewed step-by-step plan) → the core loop. A raw idea (anything else) → run the full-lifecycle wrapper first (REQUIRED: `references/wrapper.md`). **`--profile audit` / `--profile debug` (or an audit-/debug-intent task) → skip the wrapper + plan-writing:** `audit` goes straight to the audit fan-out (`references/audit.md`) — no idea to brainstorm, no plan to write; `debug` goes **reproduce-first** straight to its investigate→fix loop — the failure *is* the spec, so there is nothing to brainstorm or plan (the gate enforces reproduce-then-resolve, `references/gate.md`). Both still run the produce→gate→fix→integrate loop (`audit`'s `integrate` is a no-op, `debug`'s lands the fix); only the wrapper + plan-writing are skipped.
3. **Run the core loop** over each workstream. **For EVERY workstream → dispatch a producer; there is no inline path.** REQUIRED: `references/loop.md`, gating each via `references/gate.md`.
4. **Report** each workstream's gate verdict + a short end-of-run **decision log** of the conductor's key calls (the run's report output only — **stateless**, never a persisted store; `references/loop.md` §Report); pause only for genuine decisions/blockers, **classified per §Autonomy** (a User-Challenge pauses even under `auto`). Then run the retro (if `--retro` on, the default) and surface learnings + any proposed skill deltas (`references/retro.md`).

## Autonomy
The `--autonomy` mode sets the baseline **cadence** (how often the conductor pauses); the **decision taxonomy** below refines it — deciding *which* mid-run decisions warrant surfacing or a pause even under `auto`. The two compose; the taxonomy never relaxes an explicit `confirm`/`step` (those still pause as stated).

- **auto** (default): propose the dreamteam → proceed; report at each gate; pause only for real decisions (a **User-Challenge**, per the taxonomy).
- **confirm**: confirm the dreamteam, and each gate verdict, before continuing.
- **step**: pause after every workstream.

### Decision taxonomy (which mid-run decisions warrant a pause)
When a decision arises mid-run — a roster/tier/scope pick, an ambiguity, a direction the gate or a producer wants to take — classify it before acting:

- **Mechanical** — objectively determined; one defensible answer fixed by the plan, a constraint, or evidence. → **Just proceed** (silent under `auto`).
- **Taste** — defensible either way; a judgment with no single right answer and low/reversible cost. → **Proceed, but note the choice** (and the alternative not taken).
- **User-Challenge** — a real judgment call, an **assumption** that would change the user's stated direction, or an **irreversible-or-costly** step. → **PAUSE and ask**, never auto-decided — in **every** mode, including `auto`.

**On a User-Challenge, present the four-part frame and DEFAULT TO THE USER:** (1) the user's stated direction, (2) the recommendation + why, (3) acknowledged blind-spots, (4) the **cost-if-wrong** — then default to the user's choice unless they change it. This is dreamteam's user-sovereignty posture made precise, not a relaxation of `confirm`/`step`.

Taste and User-Challenge decisions (and any noteworthy Mechanical one) are recorded in the end-of-run **decision log** — stateless, in the run's report only (`references/loop.md` §Report).

## Resilience
- Agent unavailable → the Caster picks an alternate or flags it.
- The gate's fix loop is capped (`gate_policy.max_fix_iterations`); on exhaustion, escalate to the human — never weaken the bar to force a pass.
- **Dispatch failures are recovered, never absorbed:** a dispatched unit that errors or drops without returning is re-dispatched **once, same tier, same brief** (an infrastructure error is not a reasoning failure — no tier bump); in Workflow mode a reviewer dropped at the structured-output retry cap re-runs **schema-free**, and a half-failed stage is **resumed** (`resumeFromRunId`) rather than re-run fresh (`references/loop.md` §"Dispatch-failure recovery"). A **placeholder review response** (a literal filler, a bare "LGTM") is a **reviewer error, never a verdict** — it never counts toward `min_pass` (`references/gate.md` §"Verdict admissibility").
- **Run-level caps are mechanical, not advisory** (`run_policy` in `references/caster.md`): a run-wide `max_concurrent_agents` (default 8, hard ceiling 16), a cumulative `max_total_dispatches` backstop (default 60 → on reaching it, **STOP and escalate to the human, never silently continue**), and `max_depth: 1` (the firewall guarantees it). A large projected fan-out hits a budget-print + confirm-gate before running (`budget_confirm_at`, default 30 — generalizes `--depth exhaustive` / `--evolve` to any large run).
- **Honest limitation of the prose fix.** On the background-subagent path (4 of 5 CLIs + Claude Code's default mode) the firewall and the `run_policy` caps are **model-compliance rules + tripwires, NOT a hard runtime kill-switch** — the identity firewall is the most compliance-robust prose form available (unconditional, placed first, role-keyed, delivered on both the skill body and every dispatch brief), and the numeric caps are tripwires that catch a runaway, not sandboxed guarantees. Where a hard limit exists (Claude Code + the Workflow tool's own limits, where they apply) it remains as a second layer underneath, but the design does not rely on it.
- **Opt-in hard layer (Claude Code only).** Measured fact: Claude Code fires `PreToolUse` hooks in-session **and inside dispatched subagents** — a leaf's tool calls carry a non-null `agent_id`, the conductor's are `null` — so a bundled, **opt-in** hook (`hooks/dreamteam-run-policy.js`, armed by `DREAMTEAM_ENFORCE=1`, **off by default**) turns the **leaf firewall** and the **`max_total_dispatches`** backstop into real `deny`s: a genuine second layer, not just a tripwire. It is **fail-open** (any error → allow) and **Claude-Code-only**; the prose guards stay the default and remain the sole layer on the other four CLIs. `budget_confirm_at` and the Bash-timeout discipline stay prose (a projection / harness-owned, not a per-call block). See `hooks/hooks.json`.

## Composes (do not reinvent)
REQUIRED SUB-SKILLS: `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:using-git-worktrees`, `superpowers:verification-before-completion`, `superpowers:finishing-a-development-branch`, `find-skills`.
OPTIONAL: `ponytail` — the external **enforcer** of dreamteam's native minimal-code principle (see Overview); when installed, the Caster attaches it to code-producing producers. The principle holds without it (the gate always checks over-engineering) — ponytail just enforces it harder. Cross-platform, like dreamteam.
OPTIONAL: `karpathy-guidelines` — a second composed principle-enforcer for **code-producing** producers (surface assumptions, surgical/minimal-diff changes, verifiable success criteria); like `ponytail`, the Caster attaches it to code producers when installed (`find-skills`-gated, degrades gracefully if absent). Its guidelines already ride in `loop.md`/`gate.md` — composing the skill just makes producers carry them explicitly.
OPTIONAL (highlighted): `superpowers:systematic-debugging` — the structured root-cause method dreamteam **reaches for on debug tasks and composes in the `debug` profile** (decision #7): attached to the investigator's `skills[]` when installed (`find-skills`-gated, degrades gracefully — `root-cause-analyst` investigates natively if absent). Pairs with the gate's **reproduce-then-resolve** check (`gate.md` §3).
OPTIONAL: `ui-ux-pro-max` — the **depended** design skill the `ux-designer` profile composes onto `UI Designer` when installed (`find-skills`-gated, degrades gracefully — UI Designer designs natively if absent, and a11y stays **non-waivable** either way). Not vendored; install via `references/recommend.md`.
OPTIONAL: `graphify` — an external **AST code-graph** tool the conductor keeps as **navigation infra** (codebase understanding for the `audit` profile + dev producers/Code Reviewer), gated by `--graph on|off|auto` (default `auto`). AST-only and free to refresh; **skip-if-absent, never auto-installed** (recommend-only via `references/recommend.md`), `find-skills`/tool-gated, degrades gracefully. It is **never a workstream and never decides a verdict** — graph-derived claims that would gate a workstream are verified against live code/tests (`references/loop.md` G0/G1 + §Graph invariant, `references/audit.md`). Cross-platform via its CLI / MCP server / git-hook (`references/platforms.md`).
OPTIONAL: `references/recommend.md` — when the best-fit skill isn't installed, the Caster surfaces an advisory recommendation (skills.sh + awesome-claude-code); an opt-in gated `setup` role can install an approved one. Skills-only; the Caster never installs.
OPTIONAL: `references/audit.md` — the `audit` profile: read-only bug-finding / project-map sweeps that reuse the same loop + gate (no spec, no integrate). `--depth`/`--mode` tune it.
OPTIONAL: `references/security.md` — the stack-neutral **OWASP/STRIDE security-review method** the `Security Engineer` (or any reviewer covering the security dimension) follows when security is in scope (secrets · supply-chain · CI/CD · OWASP Top-10 · STRIDE · LLM/AI · skill-supply-chain). It rides the reviewer's dispatch brief (`references/caster.md`), feeds the normal gate (emit-time evidence + severity + confidence, `references/gate.md` §1/§3; verdict stays §2), and is a **method, not a tool or a hard dependency**. Adapted from gstack's security methodology (MIT).
