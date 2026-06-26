# Dreamteam — Domain Profiles (fast-path dreamteam rosters)

If the task clearly matches a row, use that dreamteam — no Caster-agent hop. `generic` is the table's fallback; anything richer or cross-domain → the Caster agent (`caster.md`).

**Reality Checker is in every gate** — it verifies claims against evidence (tests for code; data↔claims for research).

| Profile | Planner | Producers (role → agent [+ skills]) | Gate (reviewers) | Workstreams |
|---|---|---|---|---|
| **mobile-dev** | writing-plans | build → Mobile App Builder@standard (covers iOS · Android · cross-platform) · design → UI Designer@cheap | Code Reviewer@capable, Reality Checker@capable | sequential |
| **web** | Backend Architect | backend → Backend Architect@standard · frontend → Frontend Developer@standard · design → UI Designer@cheap | Code Reviewer@capable, Reality Checker@capable (+ Security Engineer@capable if auth/payments) | sequential |
| **ai-research** | writing-plans | *expand* → deep-research-agent@standard + AI Engineer@standard [creative-thinking-for-research, brainstorming-research-ideas, literature-review] · *polish* → AI Engineer / Technical Writer@standard [ml-paper-writing] | a methodology reviewer@capable + Reality Checker@capable | **parallel** (expand ∥ polish) |
| **devops** | system-architect | infra → DevOps Automator@standard | Reality Checker@capable, Security Engineer@capable | sequential |
| **qa** | quality-engineer | test → quality-engineer@standard + Test Results Analyzer@standard | Reality Checker@capable | sequential |
| **audit** | — no plan-writing; audit fans out directly (SKILL.md spine step 2 + audit.md) | *bugs* → Code Reviewer · Security Engineer · Performance Benchmarker · root-cause-analyst@capable (dimension reviewers act as producers) · *map* → Explore · Software Architect · system-architect@capable + a synthesizer | Reality Checker@capable (+ the dimension specialists as verifiers) | **parallel** |
| **generic** | writing-plans | work → general-purpose@standard | Code Reviewer@capable, Reality Checker@capable | sequential |

Fast-path rows list planner / producers / gate / workstreams only — they **inherit `gate_policy` defaults** (`min_pass` = all reviewers, `max_fix_iterations` = 2) and the full dreamteam-manifest field names from `caster.md`.

Fast-path rows carry default tiers (mechanical→cheap, producers→standard, reviewers→capable); max is never a default. Tiers are abstract (resolved per `references/platforms.md`; F1 Claude names accepted via back-compat), overridable via `--models`/`--cost` and adjustable by the Caster agent.

Code-producing producers (mobile-dev build · web backend/frontend · devops · qa · generic) compose **`ponytail`** (minimal-code / anti-over-engineering) when installed — attached to their `skills[]` on both the fast-path and the agent path. The gate flags over-engineering **regardless** — that's dreamteam's native minimal-code principle (see `SKILL.md`); `ponytail` just enforces it harder when installed. The ai-research *writing* roles produce papers/experiments, not production code, so ponytail applies only to any code-producing research sub-role.

**mobile-dev** drops the design-architect by default — `Mobile App Builder` already covers iOS + Android + cross-platform, so the design roster is just `UI Designer`. For visually/architecturally complex mobile work the Caster can re-add a design-architect (the "rosters are defaults; the Caster can adjust" escape hatch below).

**audit** producers depend on mode (set by `references/audit.md` — read-only by default): in *bugs* mode the dimension reviewers run **as producers**; in *map* mode the explorers/architects + a synthesizer run. It overrides two manifest fields beyond the defaults — `gate_policy.devils_advocate_on_unanimous: true` and `audit_policy.max_parallel_reviewers` (per-`--depth` defaults: shallow 2 / module 4 / exhaustive 8, ceiling 12). See `references/audit.md` for modes, `--depth`, and the read-only contract.

## Matching
Map the task to a profile by intent/keywords: mobile / Android / iOS / React Native / Flutter / Expo / cross-platform → **mobile-dev**; website / API / full-stack → **web**; experiment / paper / model / dataset / hypothesis → **ai-research**; CI / deploy / infra / k8s / terraform → **devops**; test-coverage / regression / QA sweep → **qa**; audit / review / find bugs / map the codebase / understand this repo → **audit** (test-coverage / regression stays → **qa**). No clear match → the Caster agent (do not force a profile).

`--profile android` is accepted as a back-compat alias for **mobile-dev**.

The rosters are defaults — a `--roster` override or the Caster agent can adjust them (e.g. add Security Engineer, swap a builder).
