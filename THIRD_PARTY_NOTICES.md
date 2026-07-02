# Third-Party Notices

dreamteam (Copyright (c) 2026 Adnan) is licensed under the Apache License,
Version 2.0 (see `LICENSE`). dreamteam's own code remains Apache-2.0; the
bundled third-party components below retain their original MIT license.

This file records one entry per **vendored** source: source URL, the pinned
upstream commit, the SPDX license identifier, the verbatim copyright line, the
full MIT license text, and the list of bundled files. All components from one
repository share that repository's commit, copyright, and license, so they are
grouped under a single entry (one entry per source, not per file).

## Verification basis

Every source below was fetched **live on 2026-06-27** via the GitHub API. For
each source the `LICENSE` file was read verbatim (SPDX = MIT confirmed), the
default-branch HEAD commit was pinned, and **every bundled path was confirmed to
exist as a real file at that pinned commit**. Result: 21 agents + 1 skill across
3 sources — **all confirmed present, none dropped**.

## Vendoring convention (applies to all entries)

Bundled agent prompt **bodies are kept byte-for-byte pristine** (zero fork drift,
so upstream refreshes stay clean). Only two **metadata-only** changes are applied
at vendor time (Phase C) and are not body edits:

1. **Rename** — the filename and the frontmatter `name:`/registration may be set
   to the dreamteam role (e.g. ECC `mle-reviewer` -> `methodology-reviewer`,
   ECC `security-reviewer` -> `Security Engineer`).
2. **An additive `origin:` frontmatter line** — source repo + pinned commit +
   SPDX, recording provenance in-file.

No prompt text is altered. dreamteam's tone/quality standards (no-glazing,
karpathy-guidelines) are injected at **dispatch**, never written into vendored
bodies.

## Intentionally not listed here

- **superpowers** (Copyright (c) 2025 Jesse Vincent, MIT) is **depended-on**;
  **ui-ux-pro-max** (Copyright (c) 2024 Next Level Builder, MIT) is
  **recommended** (both installed via the opt-in installer), not redistributed
  -> no notices entry, no fork drift.
- **graphify** (Copyright (c) 2026 Safi Shamsi, MIT) is **recommend-only** (an
  external tool, never vendored) -> no notices entry.
- **gstack** (Copyright (c) Garry Tan, `garrytan/gstack`, MIT) is **methodology-only**:
  its OWASP/STRIDE security approach is **adapted into `references/security.md`** and
  credited in place there, but **no gstack code is vendored** -> **no notices entry**.
  The in-place credit mirrors the ECC verification-loop adaptation's credit; the
  no-entry-because-not-redistributed mirrors graphify and find-skills.
- **find-skills** (vercel-labs/skills) is **recommend-only** and declares MIT but
  ships **no LICENSE file** -> treated as `NOASSERTION`; MIT is not asserted for
  it, and it is not vendored.

(Attribution covers only what is redistributed.)

---

## agency-agents

- Source: https://github.com/msitarzewski/agency-agents
- Pinned commit: `1189f0f9bc79a1883fee958fed627c6d11581eb7` (branch `main`, verified live 2026-06-27)
- SPDX-License-Identifier: MIT
- Copyright (c) 2025 AgentLand Contributors
- Bundled files (12 agents — all confirmed present at the pinned commit):
  - `engineering/engineering-ai-engineer.md`
  - `engineering/engineering-backend-architect.md`
  - `engineering/engineering-code-reviewer.md`
  - `engineering/engineering-devops-automator.md`
  - `engineering/engineering-frontend-developer.md`
  - `engineering/engineering-mobile-app-builder.md`
  - `engineering/engineering-software-architect.md`
  - `engineering/engineering-technical-writer.md`
  - `testing/testing-reality-checker.md`
  - `testing/testing-test-results-analyzer.md`
  - `testing/testing-performance-benchmarker.md`
  - `design/design-ui-designer.md`
- The upstream `LICENSE` is retained verbatim alongside these files in `vendor/agency-agents/` (Phase C).

### MIT License

```
MIT License

Copyright (c) 2025 AgentLand Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## ECC

- Source: https://github.com/affaan-m/ECC
- Pinned commit: `2bc924faf2f8e893bfe0af86b1931283693c30ae` (branch `main`, verified live 2026-06-27)
- SPDX-License-Identifier: MIT
- Copyright (c) 2026 Affaan Mustafa
- Bundled files (4 agents + 1 skill — all confirmed present at the pinned commit):
  - `agents/mle-reviewer.md`        (dreamteam role: `methodology-reviewer`)
  - `agents/security-reviewer.md`   (dreamteam role: `Security Engineer`)
  - `agents/build-error-resolver.md`
  - `agents/pytorch-build-resolver.md`   (the one bundled ML/Python framework exception)
  - `skills/mle-workflow/` (contains `SKILL.md`; loads from `skills/mle-workflow/` so auto-discovery works, provenance tracked here)
- Additionally attributed (adapted text, **not** a vendored file): the
  **verification-loop 6-phase checklist** is adapted into dreamteam's
  `references/gate.md` §5 (lands in Phase E). It carries an in-place credit
  ("Adapted from ECC verification-loop (MIT (c) 2026 Affaan Mustafa)") and is
  attributed here because it is ECC-derived text.
- The upstream `LICENSE` is retained verbatim alongside these files in `vendor/ecc/` (Phase C).

### MIT License

```
MIT License

Copyright (c) 2026 Affaan Mustafa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## SuperClaude (SuperClaude_Framework)

- Source: https://github.com/SuperClaude-Org/SuperClaude_Framework
- Pinned commit: `226c45cc93b865108843a669c6545d421784b68c` (branch `master`, verified live 2026-06-27)
- SPDX-License-Identifier: MIT
- Copyright (c) 2024 SuperClaude Framework Contributors
- Bundled files (5 agents — all confirmed present at the pinned commit, with valid agent frontmatter):
  - `plugins/superclaude/agents/deep-research-agent.md`
  - `plugins/superclaude/agents/quality-engineer.md`
  - `plugins/superclaude/agents/root-cause-analyst.md`
  - `plugins/superclaude/agents/system-architect.md`
  - `plugins/superclaude/agents/python-expert.md`
  - (Each is also present under `src/superclaude/agents/`; the
    `plugins/superclaude/agents/` plugin-format copies are the vendor source.)
- The upstream `LICENSE` is retained verbatim alongside these files in `vendor/superclaude/` (Phase C).

### MIT License

```
MIT License

Copyright (c) 2024 SuperClaude Framework Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
