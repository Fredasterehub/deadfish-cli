# T01-T03 Codex Implementation Prompts
> Generated for P2 restructure. Each section is a standalone Codex prompt.

---
## T01 — P2_PROJECT_TEMPLATE.md

You are Codex operating in this repo. Create **exactly one** new file: `.pipe/p2/P2_PROJECT_TEMPLATE.md`.

First, read `.pipe/p2/P2_F.md` and match its style (terse, explicit line/token limits, codefenced YAML, minimal prose). Use it as the STYLE REFERENCE.

### Goal
Create a P2 template file that P2_F can use to generate `PROJECT.md` (living project context). The template must include the **exact** `PROJECT.md` YAML schema from `.pipe/p2-p5-restructure-opus.md` section **1** (verbatim, no edits, no reformatting).

### Inputs to read
1) `.pipe/p2/P2_F.md` (style reference; read first)
2) `.pipe/p2/P2_E.md` (extra style context)
3) `.pipe/p2-p5-restructure-opus.md` (copy the exact PROJECT.md schema)

### Output (write this file)
- `.pipe/p2/P2_PROJECT_TEMPLATE.md`

### Template content requirements (what to write into `.pipe/p2/P2_PROJECT_TEMPLATE.md`)
- Keep guidance terse and skimmable; prefer bullets; avoid long prose.
- Include explicit limits (match P2_F’s pattern), e.g.:
  - `PROJECT.md (<= 80 lines)` and `~350 tokens` (or equivalent wording).
- Include a `PROJECT.md` section containing the **exact** YAML schema below, in a ` ```yaml ` code fence.
- Add guidance that explains:
  - How to derive `core_value` from P2 brainstorm (“the ONE thing that must work”).
  - Allowed `constraints[].type` values and how to choose them.
  - `key_decisions[]` format (decision/rationale/outcome/date), date format `YYYY-MM-DD`, and how/when to append new decisions.
  - When to update vs. when to leave fields blank (esp. `assumptions`, `open_questions`, `context`, `key_decisions`).
- Add field help: short descriptions + constraints + examples. Keep this compact by using:
  - A “Field notes” bullet list covering each field path at least once, AND
  - A single “Example filled PROJECT.md YAML” block that demonstrates realistic values for every field (separate from the schema block).
- Do **not** change the schema block text (comments, indentation, key order) — it must remain verbatim.

### EXACT PROJECT.md YAML schema to include verbatim
```yaml
# PROJECT.md — {project_name}
project:
  name: "<project name>"
  description: "<2-3 sentences, current accurate description>"
  core_value: "<the ONE thing that must work>"

  constraints:
    - type: "<tech|timeline|budget|dependency|compatibility>"
      what: "<constraint>"
      why: "<rationale>"

  context: |
    <Background: tech environment, prior work, known issues.
     Updated as project evolves.>

  key_decisions:
    - decision: "<choice made>"
      rationale: "<why>"
      outcome: "pending|good|revisit"
      date: "<YYYY-MM-DD>"

  assumptions:
    - "<assumption>"
  open_questions:
    - "<unresolved question>"
```

### Done when
- [ ] `.pipe/p2/P2_PROJECT_TEMPLATE.md` exists and is self-contained
- [ ] It references `.pipe/p2/P2_F.md` as style source and matches that terseness
- [ ] It contains the PROJECT.md schema block exactly (verbatim; unchanged)
- [ ] It includes concise guidance on `core_value`, `constraints[].type`, `key_decisions[]`, and update-vs-blank rules
- [ ] It includes field descriptions/constraints and an example filled YAML instance covering every field

---
## T02 — P2_REQUIREMENTS_TEMPLATE.md

You are Codex operating in this repo. Create **exactly one** new file: `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md`.

First, read `.pipe/p2/P2_F.md` and match its style (terse, explicit line/token limits, codefenced YAML, minimal prose). Use it as the STYLE REFERENCE.

### Goal
Create a P2 template file that P2_F can use to generate `REQUIREMENTS.md` (checkable requirements with IDs, categories, and traceability). The template must include:
- The **exact** `REQUIREMENTS.md` YAML schema from `.pipe/p2-p5-restructure-opus.md` section **1** (verbatim, no edits).
- The REQUIREMENTS design principles from `.pipe/p2-p5-restructure-opus.md` section **3** (“Key Design Principles”).

### Inputs to read
1) `.pipe/p2/P2_F.md` (style reference; read first)
2) `.pipe/p2/P2_E.md` (extra style context)
3) `.pipe/p2-p5-restructure-opus.md` (copy exact schema + design principles)

### Output (write this file)
- `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md`

### Template content requirements (what to write into `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md`)
- Keep guidance terse and skimmable; prefer bullets; avoid long prose.
- Include explicit limits (match P2_F’s pattern), e.g.:
  - `REQUIREMENTS.md (<= 120 lines)` and `~500 tokens` (or equivalent wording).
- Include a `REQUIREMENTS.md` section containing the **exact** YAML schema below, in a ` ```yaml ` code fence.
- Include the section “Key Design Principles” (from the restructure plan section 3) as a short numbered list in the template.
- Use (and feel free to paste verbatim) these design principles:
  1. **IDs are stable** — `AUTH-01` never changes meaning. New requirements get new IDs.
  2. **Categories derived from domain** — P2 brainstorm organizes ideas into themes → themes become categories.
  3. **Acceptance criteria are pre-tagged** — DET:/LLM: prefix assigned at P2 time, inherited by all downstream plans.
  4. **Traceability is bidirectional** — requirement → phase (in REQUIREMENTS.md) AND phase → requirements (in ROADMAP.md).
  5. **Coverage audit** — `coverage` section ensures every v1 requirement maps to a phase. Unmapped = gap.
- Add rules/guidance for:
  - **ID format**: `CAT-NN` (uppercase CAT, hyphen, 2-digit NN), stability rules (never reuse/renumber), and allocation (sequential per category).
  - **Category derivation**: derive `category` and `CAT` from P2 brainstorm themes (group success truths into domain themes).
  - **Acceptance tagging**: how to decide `DET` vs `LLM` (machine-checkable vs human/LLM judgement); mixed acceptance allowed; keep criteria testable and specific.
  - **Traceability**: `phase` field is required for `v1` items; ROADMAP phases must reference requirement IDs; bidirectional mapping expectations.
  - **Coverage audit**: how to compute/fill `coverage.total_v1`, `coverage.mapped`, `coverage.unmapped`, and what to do when unmapped > 0.
  - **Status lifecycle**: `pending → in_progress → complete → blocked` rules; when to advance status (phase start; acceptance pass; external block).
- Add field help: short descriptions + constraints + examples. Keep this compact by using:
  - A “Field notes” bullet list covering each field path at least once, AND
  - A single “Example filled REQUIREMENTS.md YAML” block that demonstrates realistic values for every field (separate from the schema block).
- Do **not** change the schema block text (comments, indentation, key order) — it must remain verbatim.

### Status lifecycle (include this exact flow somewhere in the template)
```
pending → in_progress (when phase starts)
       → complete (when all acceptance criteria pass)
       → blocked (when external dependency blocks)
```

### EXACT REQUIREMENTS.md YAML schema to include verbatim
```yaml
# REQUIREMENTS.md — {project_name}
requirements:
  defined: "<YYYY-MM-DD>"
  core_value: "<from PROJECT.md>"

  v1:
    - id: "<CAT>-<NN>"
      category: "<category name>"
      text: "<user-centric, testable requirement>"
      phase: <phase_number>
      status: "pending|in_progress|complete|blocked"
      acceptance:
        - type: "DET|LLM"
          criterion: "<testable acceptance criterion>"

  v2:
    - id: "<CAT>-<NN>"
      category: "<category>"
      text: "<deferred requirement>"

  out_of_scope:
    - feature: "<excluded feature>"
      reason: "<why excluded>"

  coverage:
    total_v1: <N>
    mapped: <N>
    unmapped: <N>
```

### Done when
- [ ] `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md` exists and is self-contained
- [ ] It references `.pipe/p2/P2_F.md` as style source and matches that terseness
- [ ] It contains the REQUIREMENTS.md schema block exactly (verbatim; unchanged)
- [ ] It includes the section 3 “Key Design Principles” and applies them to guidance
- [ ] It includes ID rules, DET/LLM tagging rules, phase traceability, coverage audit, and status lifecycle guidance
- [ ] It includes field descriptions/constraints and an example filled YAML instance covering every field

---
## T03 — P2_ROADMAP_TEMPLATE.md

You are Codex operating in this repo. Create **exactly one** new file: `.pipe/p2/P2_ROADMAP_TEMPLATE.md`.

First, read `.pipe/p2/P2_F.md` and match its style (terse, explicit line/token limits, codefenced YAML, minimal prose). Use it as the STYLE REFERENCE.

### Goal
Create a P2 template file that P2_F can use to generate the **new** `ROADMAP.md` format (GSD-style phases; replacing the old track-based format). The template must include the **exact** `ROADMAP.md` YAML schema from `.pipe/p2-p5-restructure-opus.md` section **1** (verbatim, no edits).

### Inputs to read
1) `.pipe/p2/P2_F.md` (style reference; read first)
2) `.pipe/p2/P2_E.md` (extra style context)
3) `.pipe/p2-p5-restructure-opus.md` (copy exact schema)

### Output (write this file)
- `.pipe/p2/P2_ROADMAP_TEMPLATE.md`

### Template content requirements (what to write into `.pipe/p2/P2_ROADMAP_TEMPLATE.md`)
- Keep guidance terse and skimmable; prefer bullets; avoid long prose.
- Include explicit limits (match P2_F’s pattern), e.g.:
  - `ROADMAP.md (<= 100 lines)` and `~400 tokens` (or equivalent wording).
- Include a short explanation of the shift:
  - Old: “tracks with steps/deliverables”
  - New: “phases with goals + success_criteria + requirement references” (no task-level detail)
- Include a `ROADMAP.md` section containing the **exact** YAML schema below, in a ` ```yaml ` code fence.
- Add guidance that explains:
  - Phase structure (phases are the unit; tracks are planned just-in-time later).
  - `success_criteria` must be observable and feed `verify.sh` + P9 verification; avoid vague criteria.
  - `requirements` references must be valid `REQUIREMENTS.md` IDs; explain cross-references and bidirectional traceability.
  - `depends_on` ordering rules and how to keep it minimal/accurate.
  - Progress tracking (`progress.*`) and phase status updates.
  - Project-level `risks` and `definition_of_done` (overall completion criteria).
- Add field help: short descriptions + constraints + examples. Keep this compact by using:
  - A “Field notes” bullet list covering each field path at least once, AND
  - A single “Example filled ROADMAP.md YAML” block that demonstrates realistic values for every field (separate from the schema block).
- Do **not** change the schema block text (comments, indentation, key order) — it must remain verbatim.

### EXACT ROADMAP.md YAML schema to include verbatim
```yaml
# ROADMAP.md — {project_name}
roadmap:
  version: "<version>"
  goal: "<strategic goal>"

  phases:
    - id: <N>
      name: "<phase name>"
      goal: "<what this phase delivers>"
      depends_on: [<phase_ids>]
      requirements: ["<REQ-ID>", "<REQ-ID>"]
      success_criteria:
        - "<observable behavior — feeds verify.sh + P9>"
      estimated_tracks: <N>
      status: "not_started|in_progress|complete|deferred"

  progress:
    total_phases: <N>
    completed: <N>
    current_phase: <N>

  risks:
    - "<project-level risk>"

  definition_of_done:
    - "<overall completion criteria>"
```

### Done when
- [ ] `.pipe/p2/P2_ROADMAP_TEMPLATE.md` exists and is self-contained
- [ ] It references `.pipe/p2/P2_F.md` as style source and matches that terseness
- [ ] It contains the ROADMAP.md schema block exactly (verbatim; unchanged)
- [ ] It explains the shift from tracks to phases and enforces “no task-level detail”
- [ ] It includes guidance for success criteria (verify.sh + P9), requirement cross-references, depends_on ordering, and progress/status tracking
- [ ] It includes field descriptions/constraints and an example filled YAML instance covering every field
