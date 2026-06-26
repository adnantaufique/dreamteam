# Dreamteam — The Caster (dreamteam selection)

Resolve the dreamteam for a task and **print a dreamteam manifest** (+ one line of rationale per pick) before any work runs. The Caster only *selects* — it never produces.

Skill recommendations + the opt-in installer role: `references/recommend.md` (the Caster only recommends — **discovery in, advice out**).

## Precedence (stop at the first that applies)
0. **Consult learnings** — read `references/learnings.md` for the matched profile/task_kind; treat any entry as an overridable default (adjust the roster/tiers/gate emphasis accordingly), never a hard rule. This informs — never overrides — the steps below.
1. **Explicit cast** — any of `--roster` / `--profile` / `--skills` given → build the manifest from them, skip the Caster agent.
   - `--profile X` → that row of `references/profiles.md`. Back-compat: `--profile android` resolves to `mobile-dev` (alias), and the learnings lookup key normalizes `android → mobile-dev` so persisted `references/learnings.md` rows still match after the rename.
   - `--roster planner=<agent|skill>[@<tier>],producers=<role>:<agent>[@<tier>][+<skill>…][;<role>:<agent>…],reviewers=<agent>[@<tier>][,<agent>…]` → parse into the manifest as given (Reality Checker is still force-added to `reviewers` if the user omitted it).
   - `--skills a,b` → force-include those skills, attaching them to the relevant producer(s)' `skills[]` (or to the sole producer when there is one).
   - `--models planner=<tier>,producers=<role>:<tier>;…,reviewers=<tier>` → set tiers explicitly.
   - `--cost cheap|balanced|quality` → bias the **producer** rubric (cheap: producers→cheap tier; balanced [default]: the rubric as written; quality: producers→standard/capable, max only here as an explicit opt-in for the hardest). **Reviewers never drop below capable — Reality Checker especially — regardless of `--cost`** (the honesty backbone stays strong).
   - `--roster …@<tier>` → an `@tier` suffix on any role sets that role's tier inline (e.g. `producers=build:Mobile App Builder@standard`; legacy Claude names like `@sonnet` are accepted via back-compat); a bare role keeps the rubric/profile default.
2. **Profile fast-path** — no explicit cast → try a confident profile match (the matching rules in `references/profiles.md`). Clean match → **check every agent/skill in that row is available** (the live agent list + `find-skills`). All present → use that row's dreamteam, no agent hop. **Any default missing → skip the fast-path and fall through to the Caster agent (3)**, which adapts to what is actually installed.
3. **Caster agent** — novel / ambiguous / cross-domain / no clean profile → dispatch a `general-purpose` **Caster agent** (prompt below) to reason over the live registries and return a manifest.
   - If a materially-better skill is discoverable (`find-skills` / the awesome-claude-code CSV) but not installed, record it in `recommendations[]` (per references/recommend.md) and proceed with the best installed option — never block. Explicit `--roster/--skills` casts bypass this (a missing named skill is handled by the existing find-skills existence check).

Whichever path, **Reality Checker is always in `reviewers`** (the claim-integrity backbone).

## Dreamteam manifest — the cross-file contract
Defined here once; `loop.md`/`gate.md`/`profiles.md`/`audit.md` read these field names verbatim; unknown advisory fields (e.g. `recommendations[]`) are ignored, never required.
```
{ planner: { agent|skill, model } | null,        // model only when planner is a dispatched agent
  designers: [ { agent, model } ],                // scheduled as producers; each carries a tier
  producers: [ { role, agent, model, skills[] } ],
  reviewers: [ { agent, model } ],                // reviewers now objects; Reality Checker present + capable
  gate_policy: { min_pass, max_fix_iterations, devils_advocate_on_unanimous: false, devils_advocate_min_panel: 3 },
  audit_policy: { max_parallel_reviewers },       // sibling of gate_policy, NOT nested inside it
  workstream_strategy: "sequential" | "parallel",
  recommendations: [ ... ],                       // optional, advisory, per-run ephemeral — see references/recommend.md
  rationale: [ <one line per pick, naming the tier + why> ] }
```
- **`min_pass`** — reviewers that must reach a passing verdict for a workstream to integrate (default: all reviewers). Reality Checker's pass is *always* required regardless of `min_pass`.
- **`max_fix_iterations`** — cap on fix → re-verify cycles before escalating to the human (default: 2).
- **`devils_advocate_on_unanimous`** — opt-in (default: `false`); when `true`, a unanimous pass triggers one devil's-advocate re-review before integrating. The `audit` profile sets it `true`.
- **`devils_advocate_min_panel`** — minimum reviewer count for the devil's-advocate pass to fire (default: 3); smaller panels skip it.
- **`audit_policy.max_parallel_reviewers`** — cap on reviewers dispatched concurrently per workstream (top-level sibling of `gate_policy`, read by `audit.md`).
- **`workstream_strategy: parallel`** only when workstreams are genuinely independent (e.g. ai-research *expand* ∥ *polish*); else `sequential`.
- Every `producers[].skills` entry must be a skill that actually exists — verify with `find-skills`, don't assume.
- **model** ∈ {cheap, standard, capable, max} (abstract; the concrete model is resolved per `references/platforms.md`). Back-compat: F1's Claude names (haiku/sonnet/opus/fable) are accepted and mapped. A missing model is filled by the rubric/profile default at dispatch.

## Model tier (cheapest-that-fits)
Tiers are abstract — **cheap (haiku) → standard (sonnet) → capable (opus) → max (fable)** — and the concrete model is resolved per platform in `references/platforms.md`. Assign each dispatched role the cheapest tier that fits, per subagent-driven-development's signals:
- Mechanical producer (1–2 files, complete/clear spec, deterministic) → cheap.
- Integration / judgment producer (multi-file, pattern-matching, debugging) → standard.
- Planner (when a dispatched agent, not a skill), architecture/design lead, and ALL gate reviewers (Reality Checker especially) → capable (the default ceiling).
- max is NOT a default — top escalation rung / explicit override only.
Reviewers default capable regardless of producer tiers (the honesty backbone stays strong).

## The Caster agent prompt (hand this to a `general-purpose` subagent)
> You are the **Caster** for a `/dreamteam` run. Task: «TASK». Repo/domain context: «CONTEXT».
> Select a dreamteam to do this task — do **NOT** execute any of the work yourself.
> 1. Read the **available agents** from the Agent tool's agent-type list — use the live list, not memory.
> 2. Discover relevant **skills** with `find-skills` — don't assume a skill exists; check. Also consult `references/learnings.md` for prior learnings on this profile/task_kind and fold them in as overridable defaults (cite the entry), not hard rules.
> 3. Choose: a `planner` (agent or skill, or `null` if a plan is already supplied); optional `designers` as `{agent, model}`; `producers` as `{role, agent, model, skills[]}`; a `reviewers` panel (each as `{agent, model}`) that **ALWAYS includes Reality Checker** plus any domain reviewers the task demands (e.g. Security Engineer for auth/payments/infra; a methodology reviewer for research; Performance Benchmarker for load/latency work); `gate_policy {min_pass, max_fix_iterations}`; and `workstream_strategy` (`parallel` only if the workstreams are truly independent). Then assign each role a model tier per the Model-tier rubric (reviewers default capable); name the tier in each rationale line (e.g. "build→Mobile App Builder@standard: multi-file integration"). **Producers follow dreamteam's native minimal-code principle** — the simplest solution that fully works (YAGNI ladder), complete and correct, never cutting validation/security/accessibility — regardless of which skills are attached. For **code-producing** producers, also attach the composed principle-enforcers to their `skills[]` when installed (`find-skills`, each checked independently — proceed without any that's absent): `ponytail` (the minimal-code *enforcer*) and `karpathy-guidelines` (surface assumptions, surgical/minimal-diff changes, verifiable success criteria). They amplify dreamteam's native principles; the principles hold without them.
> 4. Return **only** the dreamteam-manifest JSON above, with a one-line `rationale` per pick. No prose outside the manifest, no execution.

If a chosen agent/skill turns out to be unavailable, pick the closest alternate and say so in its rationale line (don't silently drop a role).

**Dispatch brief — the no-glazing standard (rides on every reviewer dispatch).** Whatever reviewer the manifest casts is **dispatched with dreamteam's objective / no-glazing standard in its brief**: state the unvarnished assessment, call severities by impact, and never praise-pad or soften a finding — a bare "looks good" with no specific finding is not a review (`gate.md` §3). **Vendored reviewer agent bodies are kept pristine** (`THIRD_PARTY_NOTICES.md`), so this standard rides on the **dispatch brief**, never the agent file — which is what lets it bind whatever agent is cast (vendored or host).

## Autonomy (the manifest is always printed first)
- **`auto`** (default): print the dreamteam + rationale → **proceed** to the loop.
- **`confirm`**: print the dreamteam + rationale → **wait for the user's OK** before producing.
- Explicit `--roster/--profile/--skills` always override the Caster's choice.
