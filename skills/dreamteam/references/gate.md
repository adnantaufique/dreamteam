# Dreamteam — The Gate (independent review)

Independent review of **one workstream's output** by the manifest's `reviewers` panel. Produces a verdict: **pass / fix-then-pass / needs-work**. Reality Checker is always on the panel and its pass is mandatory — the gate exists to keep claims honest.

## 1. Dispatch the panel — parallel, split by resource use
Run reviewers concurrently, but split them so they don't collide on shared build/runtime resources:
- **Static reviewers** (read-only — Code Reviewer, Security Engineer reading code, a methodology reviewer): run all in parallel; they only read.
- **Verifying reviewers** (run the build / tests / experiment / load — Reality Checker, Performance Benchmarker): these contend for Gradle, an emulator, a GPU, ports. Don't run two contending verifiers on the same resource at once — serialize those, or isolate each in its own worktree/sandbox.

Each reviewer returns **findings** (each with severity Critical/High/Medium/Low **+ evidence**) and a **per-reviewer verdict**.

Each reviewer is dispatched at its manifest model tier (default capable; Reality Checker stays capable — the claim↔evidence check must be strong). The gate's verdict logic is model-agnostic; only the dispatched reviewer's tier changes.

**Over-engineering is a standing finding — always checked, with or without `ponytail`.** The Code Reviewer flags unnecessary complexity / speculative generality / gratuitous scaffolding: the **simplest solution that fully works** wins, by the ladder *does it need to exist? (YAGNI) → stdlib → native → existing dependency → one line → the minimum that works*. The solution must stay **complete and correct** and **never** cut validation, security, or accessibility — and flags **gratuitous diff scope**: changes beyond what the task requires (unrequested refactors/reformatting of untouched code) are a finding, same as over-engineering. (This is dreamteam's native minimal-code principle, per `SKILL.md`; the `ponytail` skill, when composed, enforces it more rigorously.)

## 2. Synthesize — the conductor does this, visibly
1. **Dedup** findings that name the same root cause across reviewers.
2. **Prioritize** Critical → High → Medium → Low.
3. **Reconcile conflicts with evidence.** If one reviewer *predicts* a problem and another reviewer's hard evidence (a green build, a passing test, a benchmark, the data) *refutes* it → **the evidence wins: drop the refuted finding** and note why. Evidence beats opinion: unproven claims are guilty-until-evidenced; a predicted finding loses to hard evidence. (A finding that evidence does *not* touch still stands.) A **graph-derived finding** (from `graphify`/`--graph`) is itself a prediction — an **unconfirmed candidate** until reproduced against live code/tests (`INFERRED`/`AMBIGUOUS` edges are hints, not facts), so the graph **never decides a verdict** (`loop.md` §Graph).
4. **Decide the verdict:**
   - **pass** — no surviving Critical/High; `min_pass` reviewers passed; Reality Checker passed.
   - **fix-then-pass** — surviving Critical/High must-fixes that are bounded and fixable in-loop.
   - **needs-work** — fundamentally off (wrong approach, unmet requirement, or Reality Checker failed on integrity) → escalate; do not paper over.

**Must-fixes = the surviving Critical/High findings** after reconciliation.

**Devil's advocate on unanimous pass.** When the reviewer panel is **unanimous-pass** AND its size ≥ `gate_policy.devils_advocate_min_panel` AND `gate_policy.devils_advocate_on_unanimous` is true, the conductor dispatches **one** additional `capable` reviewer charged to **refute the consensus**. Its findings are **evidence-reconciled like any other** (a mere prediction loses to hard evidence — it cannot veto a genuinely clean result); then re-decide the verdict. This runs **once per gate, OUTSIDE the fix loop** — no nesting, no looping. Default off (cheap profiles don't pay for it); the `audit` profile turns it on.

## 3. Honesty rule — non-negotiable (the reason the gate exists)
- **Reject faked or over-claimed coverage.** "Tests pass" with no test, assertions of `true`, skipped/commented-out tests, or coverage numbers with no run → automatic must-fix, never a pass. A passing test must be **non-vacuous**: the verifying reviewer confirms it **would fail if the code under test were broken**, and that **mocks do not stand in for the unit under test** — reason about it always; perturb the implementation to confirm red when cheap (not a mandate to run mutation tooling on every gate). A green suite that survives a broken implementation is vacuous coverage → must-fix, never a pass.
- **Evidence, not trust.** A verifying reviewer **re-runs** the build/tests/experiment itself; it never takes the producer's word for it. For a **setup/install** workstream, the verifying reviewer confirms **(a)** the skill is now present (the `find-skills` availability check), **(b)** the installed identity == the approved candidate (owner/repo@skill + source — no substitution/typosquat), **and (c)** the **dispatched install command** was the pinned approved one carrying **no `-y`/auto-confirm flag**. Any mismatch — including a `-y` invocation even if the right package landed — is a needs-work, never a pass.
- **Label the proof honestly.** Distinguish **unit-tested** vs **integration-tested** vs **manual-only** vs **unverified** — and never let a lower tier be reported as a higher one. For research: the **data must actually support the claim** (Reality Checker checks data ↔ claim), not merely be cited.
- **Profile-specific claim↔evidence (generalizing the research data↔claim check).** The Reality Checker's claim-integrity check takes the form the profile demands — same rigor, different evidence:
  - **debug → reproduce-then-resolve.** First **reproduce** the reported failure as a test that is **RED against the original (unfixed) code**, then confirm the fix turns it **GREEN**, locked by a **regression test**. A "fix" whose test passes **even against the original bug** proves nothing → **rejected as vacuous**, never a pass (the non-vacuous rule above, pinned to the *specific reported failure*). Resolving without first reproducing is unverified — a needs-work.
  - **tutor → explanation↔source.** Every claim in an explanation must **trace to a cited source**; an uncited assertion is `unverified`. On any **explanation↔source conflict the SOURCE WINS** — no "lies-to-children": a simplification that is *false* (not merely incomplete) is a must-fix, never a pass. Pair with the clarity rubric (reading level · jargon defined on first use · ≥1 worked example), but accuracy gates first.
  - **ux-designer → a11y is a standing NON-WAIVABLE dimension.** The Reality Checker **re-derives** the accessibility evidence — contrast ≥4.5:1, visible focus, `prefers-reduced-motion` honored, semantic structure, spec↔rendered parity — never taking the producer's word. An a11y failure is **always a must-fix**, never traded for aesthetics, speed, or scope, and minimal-code may never cut it (consistent with §1's "never cut … accessibility" and `SKILL.md`'s minimal-code principle). This dimension holds **even when `ui-ux-pro-max` is absent**.
- Violating the letter of this rule violates its spirit: a green checkmark with no evidence behind it is a failed gate.
- This rule is `superpowers:verification-before-completion` applied to review — claims of done/passing require run evidence, not assumption.
- **No glazing — be objective (distinct from the evidence rules above).** Every reviewer states the **unvarnished** assessment: no praise-padding, no hedging a real problem into a gentle suggestion, no rounding a fix-then-pass up to a pass to be agreeable. Severity is set by **impact**, not by tone — a Critical is reported as Critical even when the surrounding work is strong. A bare "looks good" / "LGTM" with no specific finding is **not** an assessment and **not** a passing review. This governs *how* a finding is voiced (objectivity); the bullets above govern *whether it has evidence* — both are required, and neither substitutes for the other.

## 4. Capped fix loop
```
iterations = 0
while must-fixes remain and iterations < gate_policy.max_fix_iterations:
    dispatch the producer with the must-fix list
    re-run the verifying reviewers on the changed output   # re-verify — don't assume the fix worked
    re-synthesize (§2)
    iterations += 1
if must-fixes still remain:
    escalate to the human — never weaken the bar to force a pass
```
Report the final verdict, what was fixed, and **the evidence behind the pass**.

Reviewers do not auto-escalate tiers (already capable); producer re-dispatch escalation is handled in `loop.md`.

## 5. Verification checklist (stack-neutral appendix)

A concrete, stack-neutral sequence the **Reality Checker** / **Code Reviewer** MAY run as the verifying pass on a code workstream — it operationalizes §3's "evidence, not trust." Run in order:

1. **build** — the project builds / compiles / installs cleanly.
2. **types** — type-check / static analysis passes (typed stacks).
3. **lint** — linter / formatter reports no new violations.
4. **tests + coverage** — the suite runs green and exercises the changed code; coverage comes from a **real run** and the tests are **non-vacuous** (§3).
5. **secret-scan** — no credentials / keys / tokens introduced in the diff.
6. **diff-review** — every changed line traces to the task; no gratuitous scope (§1).

→ **PASS** only when every *applicable* phase passes; any failing phase is a must-fix (§2). A phase that genuinely doesn't apply (e.g. `types` on an untyped script) is **labelled `skipped` with a reason — never silently faked green** (§3). This is a checklist the verifying reviewer may follow, **not** new gate machinery — the verdict still comes from §2.

*Adapted from ECC verification-loop (MIT © 2026 Affaan Mustafa); attribution in `THIRD_PARTY_NOTICES.md`.*
