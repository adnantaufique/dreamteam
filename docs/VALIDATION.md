# Validation scenarios

These are the subagent dry-run scenarios dreamteam ships with. There's no compiler to run, so they double as the test suite: each one dispatches a fresh `general-purpose` subagent against the named skill files plus an input, and the subagent's behavior is the test. The list below is the index, in order; the full Input/Expected spec for each scenario lives in [tests/scenarios.md](../tests/scenarios.md). Re-run after any edit, and install first.

## Core loop, selection, and learning (S1–S12)

- **S1** — the profile fast-path resolves "build an Android TV app" to the mobile-dev crew, with gate [Code Reviewer, Reality Checker] and each role's default tier.
- **S2** — with no profile, the Caster agent returns a coherent manifest: planner, producers, reviewers including the Reality Checker, gate policy, and a one-line rationale per pick.
- **S3** — gate synthesis keeps the evidenced resource leak as the must-fix and drops the refuted build-break prediction (evidence beats prediction), landing fix-then-pass.
- **S4** — the per-workstream produce→gate→fix→integrate loop gives each parallel file-mutating producer its own git worktree and integrates only on a pass.
- **S5** — an installed-skill dry-run prints the web crew (plus Security Engineer for auth) with rationale, then stops for confirmation instead of executing.
- **S6** — tier assignment puts the mechanical role at cheap, the integration role at standard, and reviewers at capable, with max never a default.
- **S7** — a needs-work fix re-dispatches one tier up (cheap→standard), capped at max_fix_iterations before escalating to a human, while NEEDS_CONTEXT stays put and just adds context.
- **S8** — the retro emits evidence-tagged learning deltas, flags any skill-editing delta as proposed and human-gated, and records nothing it can't cite from run evidence.
- **S9** — the Caster applies a seeded learning as an overridable default (the `android` key normalizes to mobile-dev), not a hard rule.
- **S10** — an `--evolve` dry-run describes the opt-in, ai-research-only generations loop with its per-generation reviewers, budget, and human gate, without executing.
- **S11** — tiers and the back-compat `sonnet` name resolve correctly across Claude, Gemini, Codex, CodeWhale, and OpenCode, each with the right dispatch verb.
- **S12** — the conductor dispatches every workstream, including a one-line README badge, cites the governing rule, and pauses rather than producing inline if dispatch is unavailable.

## Minimal-code and the recommendation system (S13–S17)

- **S13** — minimal-code is native: the gate flags over-engineering with or without `ponytail`, and `ponytail` attaches to the code producer as the enforcer when installed.
- **S14** — the Caster records a verified advisory recommendation, proceeds with the best installed option, never blocks, and omits the recommendation when nothing clears the quality bar.
- **S15** — non-skill Claude resources are sourced from the awesome-claude-code CSV (installable:false, health-filtered) and suppressed under any non-Claude platform.
- **S16** — an approved, gated `setup` producer runs the one pinned command with no `-y`; the gate checks installed identity and the command itself, rejecting `-y`, typosquats, and an auto bypass.
- **S17** — the dispatch carries an explicit success criterion, the gate raises both over-engineering and gratuitous diff scope, and genuine spec ambiguity returns NEEDS_CONTEXT rather than a silent guess.

## Audit profile and gate sharpenings (S18–S22)

- **S18** — in `audit --mode bugs` the dimension reviewers fan out as producers, the gate confirms real bugs and drops false positives, integrate is a no-op, and a bare `--profile audit` defaults to bugs.
- **S19** — `audit --mode map` returns a structured project model, depth changes fan-out breadth, and exhaustive is budget-printed, confirm-gated, and capped by max_parallel_reviewers.
- **S20** — a test that survives a deliberately broken implementation, or that mocks the unit under test, is a must-fix even though it is green.
- **S21** — a 3-reviewer unanimous pass triggers one adversarial reviewer once (its unevidenced prediction is dropped); a 2-reviewer pass does not, and it is off by default outside `audit`.
- **S22** — Android, React Native, and iOS tasks plus `--profile android` all resolve to mobile-dev, and a learnings row keyed `android` still matches the renamed profile.

## Execution mode and session stickiness (S23–S25)

- **S23** — the conductor always dispatches in the background, asks once per session whether to use background subagents or the Workflow tool (Workflow on Claude Code only), and still awaits each result before gating.
- **S24** — after a run the session is sticky: further artifact tasks go through dreamteam, Q&A is answered directly, only a stated and bounded tiny edit may go inline, and "stop using dreamteam" disarms it until the next `/dreamteam`.
- **S25** — `--execution` pre-sets the one-time session mode and skips the prompt; `workflow` on a non-Claude platform is invalid and falls back to background, and no-flag behavior is unchanged.

## Bundled agents, attribution, and added profiles (S26–S40)

- **S26** — plugin.json registers the 21 vendored agents (12 agency-agents + 4 ECC + 5 SuperClaude) and auto-loads `mle-workflow`, all with no external install, while per-source LICENSE and THIRD_PARTY_NOTICES entries hold and the root LICENSE stays Apache-2.0.
- **S27** — the ml-dev profile resolves its build, build-fix, and gate roles (methodology-reviewer + Reality Checker) and stays distinct from ai-research, with bundled skills present by default.
- **S28** — the debug profile goes reproduce-first (skipping the wrapper and plan-writing), gates RED-before / GREEN-after plus a regression test, rejects a vacuous fix, and unlike audit it lands the fix.
- **S29** — the ux-designer profile composes ui-ux-pro-max, adds deep-research-agent for a redesign (omitted greenfield), and re-derives non-waivable a11y evidence, branching spec-only versus code-emitted.
- **S30** — the tutor profile pairs deep-research-agent with Technical Writer and gates explanation↔source (source wins, no false simplifications) plus a clarity reviewer, while "map this codebase" still routes to audit.
- **S31** — code-producing producers compose `karpathy-guidelines` on both selection paths, degrade gracefully when it is absent, and non-code roles do not carry the code enforcers.
- **S32** — a bare "looks good" is not a passing review, severity is set by impact rather than tone, and the no-glazing standard rides on every reviewer dispatch without editing the vendored agent bodies.
- **S33** — the optional 6-phase verification checklist runs in order with per-phase evidence, labels inapplicable phases skipped, passes only when every applicable phase passes, and carries its ECC attribution.
- **S34** — the AST-only graphify graph is conductor infra: built once, refreshed un-gated at integrate, skipped silently when absent, never a producer, and never deciding a verdict.
- **S35** — in a graphify-backed audit the graph is built once at fan-out, is the substrate for `map` and navigation-only for `bugs` (findings still reproduced against live source), and the report still ships when it is absent.
- **S36** — all six component upstreams surface with real commands carrying no `-y`, each labelled by role, with the Claude-only `/plugin` form falling back to git/npx/pip off-Claude; the Caster recommends, never installs.
- **S37** — the retro stamps each learning with a project_key (git-remote hash) and a numeric confidence (0.3–0.9), and the Caster consults only global plus current-project entries, weighted by that confidence.
- **S38** — the installer prints the registered install commands and prompts (default N) only when a required or recommended item is missing and the shell is interactive; it never auto-installs, and bundled agents are never in the prompt set.
- **S39** — the published marketplace path and the install.sh / install.ps1 manual fallback land the same bundle, and the README notes the marketplace is public but not yet client-tested.
- **S40** — dreamteam loads as a native OpenCode skill (auto-read from `~/.claude/skills`, or synced to `~/.config/opencode/skills`), dispatches via the task tool with provider-agnostic tiers, and runs background-only with no Workflow tool.

## Gate and autonomy hardening (S41–S45)

- **S41** — an unevidenced finding is unverified at emit time: it does not count and is never a must-fix until re-raised with the motivating `file:line`, command output, or reproducing case, while an evidenced (even low-confidence) finding still counts.
- **S42** — confidence ranks findings for display but never hides one: a high-severity low-confidence finding still surfaces, must-fix stays keyed to severity, and the Reality Checker always reports.
- **S43** — under `--autonomy auto` the conductor proceeds on Mechanical and Taste calls but pauses on a User-Challenge, presenting the four-part frame and defaulting to the user.
- **S44** — the run report closes with a stateless decision-log table (report output only, no persisted or event-sourced store) and prints "no notable decisions" when there were none.
- **S45** — the security reviewer may follow the stack-neutral OWASP/STRIDE method scope-aware and infra-first, its findings enter the gate like any other with no new verdict, and the gstack methodology-only attribution is present.

## Run-level safety (S46–S48)

- **S46** — a dispatched leaf does its one briefed task and returns: it never re-invokes `/dreamteam`, orchestrates, or spawns further subagents; session stickiness and the conductor rules bind only the main session; and both the `<SUBAGENT-STOP>` block and the leaf-firewall dispatch brief hold the depth-1 invariant by identity rather than a counter.
- **S47** — the `run_policy` caps are mechanical and on by default: excess concurrency serializes rather than fanning wider (8, ceiling 16), reaching the cumulative dispatch backstop (60) stops the run and escalates to a human, and a large projected fan-out (30) prints its cost and waits for confirmation even under auto.
- **S48** — execution discipline: a producer watches each shell command to completion and reads its output before proceeding, uses a bounded poll for a backgrounded command, and never abandons the task in an open-ended wait state.

## Gate resilience (S49–S50)

- **S49** — a dispatched unit that errors or drops without returning is re-dispatched once at the same tier with the same brief (no tier bump on an infrastructure error), a reviewer dropped at the schema retry cap re-runs schema-free, a half-failed stage resumes via `resumeFromRunId` rather than re-running fresh, a dropped reviewer never counts as a pass, and every re-dispatch counts toward `max_total_dispatches`.
- **S50** — a placeholder review ("Test.", a bare LGTM) is a reviewer error rather than a verdict: it earns one re-dispatch, never counts toward `min_pass`, its evidence-less finding never becomes a must-fix, and an admissible verdict must show its work — the verdict-level counterpart of S41's per-finding evidence rule.

## Cost-proportional gating (S51–S52)

- **S51** — with `risk_scaling` on (the default) the gate dispatches a risk-scaled reviewer subset per workstream (low → Reality Checker only, standard → plus the most relevant domain reviewer, high → the full panel; security in scope → `high` by the sensitive-surface heuristic), always keeping the Reality Checker and force-including any in-scope non-waivable reviewer, counting `min_pass` over the dispatched subset, printing the class in the re-anchor line (`risk off` when scaling is off or the panel pinned), and pinning the full panel under `off`, `--full-gate`, `--cost quality`, or an explicit roster — audit's own fan-out untouched.
- **S52** — on platforms with an effort dial (Codex; Claude Code Workflow mode) a cheap-tier mechanical producer may run at low effort while reviewers never drop below the platform default; the dial complements the tier rubric rather than substituting for a tier drop, and the Agent-tool / background path simply has no dial, which is not an error.

## Accuracy: refuter + reliability (S53–S54)

- **S53** — once per gate, before the first fix iteration only (never on needs-work, never inside later iterations), each must-fix that is a prediction gets one standard-tier refuter charged to run the check that settles it: hard refuting evidence drops the finding per evidence-beats-prediction, no evidence leaves it standing, an already-evidenced must-fix gets no refuter, and the refuter is an evidence-producer rather than a reviewer — the capable reviewer floor holds and its dispatches count toward the run cap.
- **S54** — the report buffer carries a per-role dispatch-reliability tally (drops by failure class, recovery re-dispatches, schema-free re-runs, refuter outcomes) the retro's feedback reviewer can cite as run evidence for a learning; it is report output only, with no persisted store.

## Dispatch efficiency (S55–S57)

- **S55** — a fix iteration re-verifies the delta (must-fix confirmation plus the fix's own diff), never a fresh full review of the workstream, while a fix that expands beyond the reviewed diff is re-classified over the expanded surface and gets a fresh review by the panel of its re-derived risk class — after which the expanded files join the reviewed diff, so a later fix re-touching them gets delta re-verification rather than a second fresh review — with §2 re-synthesis unchanged.
- **S56** — every post-cast dispatch brief opens with the byte-identical firewall-first fixed-order preamble of standing briefs (security occupying its slot only when cast) and all per-leaf content strictly after; no rule's content changes — the ordering rule costs nothing on platforms without prefix caching, and caching hits the shared prefix where supported.
- **S57** — each dispatch hands the unit its working set (file paths, entry points, graph pointers when the graph is on); a leaf that must step outside it says so in its return, and a fundamentally wrong set escalates as NEEDS_CONTEXT with a same-tier re-dispatch.

## Budget-aware scaling (S58)

- **S58** — in Workflow mode with a user token target the conductor honors the harness's live token budget as a run ceiling alongside the static caps (the budget projection incorporates it), degrading by scheduling only — serialize, then defer or shrink the remaining fan-out, then stop and escalate — never weakening the gate (no risk reclassification, no sub-class panel, no dropped Reality Checker or non-waivable reviewer, no tier-floor or honesty relaxation; a run that can't afford its gates stops); background and non-Claude runs keep the static caps as the only layer, which is correct behavior rather than an error.

## Grounding dry-runs

- **Grounding A** — `/dreamteam "build an Android TV app from its spec"` picks the mobile-dev crew (Mobile App Builder + UI Designer), sequential workstreams, gate [Code Reviewer, Reality Checker].
- **Grounding B** — `/dreamteam --profile ai-research` on a research salvage picks the ai-research crew with two parallel workstreams (expand ∥ polish), gate [a methodology reviewer, Reality Checker].
