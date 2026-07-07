# dreamteam tests

`scenarios.md` is the source of truth: **S1–S68 + Grounding A/B**, each a prose **Input → Expected** spec, judged by giving a fresh subagent the named skill file(s) + the input (see its preamble).

`run-scenarios.{ps1,sh}` is a **live spot-check harness** for a *subset* of those scenarios. Per selected ID it:

1. parses the scenario block out of `scenarios.md` and collects the skill files cited in its heading + Input line (`SKILL.md`, `references/*.md`; the phrase "installed skill" pulls the whole skill tree),
2. sends the files + Input to headless `claude -p`, asking what the skill requires the conductor/unit to do,
3. sends that response + the scenario's Expected to a second `claude -p` judge, which must answer `PASS: <one line>` or `FAIL: <specific miss>`,

then prints a per-scenario table (ID | RESULT | note) and a summary.

## Usage

```
pwsh tests/run-scenarios.ps1 -List                 # print available scenario IDs
pwsh tests/run-scenarios.ps1 GroundingA S49        # run selected scenarios
pwsh tests/run-scenarios.ps1 -Extract S49          # parse-only: block + cited files, no model calls
pwsh tests/run-scenarios.ps1 -TimeoutSec 300 S5

bash tests/run-scenarios.sh --list
bash tests/run-scenarios.sh GroundingA S49
bash tests/run-scenarios.sh --extract S49
TIMEOUT_SECS=300 bash tests/run-scenarios.sh S5
```

No default set: invoking with no IDs prints usage + the cost warning and exits 1. Exit 0 only if every selected scenario PASSed. A claude CLI failure or timeout is an **ERROR** row (distinct from FAIL) and also exits non-zero. Raw prompts/outputs are left in a temp dir (path printed) for inspection.

## Cost

Each selected scenario spends **two billed model calls** (`claude -p` run + judge). "Installed skill" scenarios (S5, S12, S46, Grounding A/B — the only whole-tree hits, per `--extract`) inline the whole skill tree (~160 KB) into the run prompt — the most expensive kind.

## Requirements

- `claude` CLI on PATH and authenticated
- the repo layout it ships in: `tests/scenarios.md` + `skills/dreamteam/{SKILL.md,references/*.md}` (paths anchor to the script's own location, so it runs from any cwd)
- PowerShell 7 (`pwsh`) or bash; nothing else

## Limits — read before trusting a result

- **LLM-judged and non-deterministic.** Both the dry-run and the verdict come from a model. A PASS is a spot-check, **not CI proof**; a FAIL is a lead to investigate, not automatically a regression. `scenarios.md` remains the source of truth — re-judge there.
- **Only skill files are inlined.** Repo files outside the skill tree (`install.sh`, `plugin.json`, `THIRD_PARTY_NOTICES.md`, sync scripts, ...) are never inlined. Measured with `--extract`: S26/S38/S39 retain no skill-file citation and fall back to `SKILL.md` alone; S40/S65 get their cited `references/platforms.md` + `SKILL.md` (not a fallback — the sync scripts are never inlined). None of the five is faithfully testable here.
- The judge sees each scenario's Expected line verbatim; the "judge coherence, not exact agent picks" nuance is left to the judge model's discretion.
