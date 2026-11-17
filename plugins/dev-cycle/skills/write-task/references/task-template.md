# Task file template

Include a section only when relevant; an empty one is omitted or says "Not required" with a
reason. Goal, Open decisions, Open questions and risks in the user's language; the rest in
compact English. Keep headings a bundle already uses. Frontmatter per
[`task-layout`](../../task-layout/SKILL.md#task-file-frontmatter).

````md
---
id: T05
status: formed
blocked_by: [T02, T03]
blocks: [T08]
milestone: P02           # optional
---

# Task: T05. <task name>

**Status:** formed · **Milestone:** [P02](../02-task-sequence.md#p02-...) ·
**Depends on:** `T02`, `T03` · **Unlocks:** `T08`.

**Execution:** skill `execute-task`. Base: `<commit>` (`<branch>`).

## Goal

<1–3 paragraphs: what gets built, which scenarios it closes, what it gives the next tasks.>

## Open decisions

| Question | Who decides | What it changes | Default | How the task proceeds |
| --- | --- | --- | --- | --- |

## Plan and invariants

<Card in `02-task-sequence.md`, deliverable, Depends on / Unlocks; invariants, decisions and
decision records the task must keep.>

## Scope

### In scope

- <modules, migrations, schemas, commands, docs created or extended>

### Out of scope

- <deferred item, reason, link to the task or workflow section>

## Current base and dependencies

| Element | Exists | Action | Evidence |
| --- | --- | --- | --- |

## Target model / contract

<Only what another task or an outside consumer reads: schemas, signatures, migrations, file
formats, as skeletons without bodies. Everything else: the outcome and its constraints.>

## Changes by layer

### Data and models

### Service / CLI / API

### UI

### Contracts, schemas, docs

## Access

| Operation or element | Permission | Who | On denial | Test |
| --- | --- | --- | --- | --- |

## Subagent-ready work items

| ID | Where | Why delegate | Context | Allowed changes | Result | Check | Before | Parallel |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S01 | Tests | focused test for criterion N without the whole context | `<3–7 files>` | `<exact test paths>` | patch | `<test command on those paths>` | implementation | yes |
| S02 | Service | one repository method behind the ready contract | `<3–7 files>` | `<exact paths>` | patch | `<test command on those paths>` | adapter | after S01 |

## Invariants and failure semantics

<What stays true; how the system fails: exit codes, HTTP statuses, job outcomes, no partial
state.>

## Implementation plan

<Suggested, not binding, at most ten lines: the developer may build it another way without editing this file.>

1. contract → 2. logic → 3. adapter → 4. tests → 5. docs

## Acceptance criteria

1. <One checkable case: the command, test or UI action that proves it, and the expected result. Smoke on the stand for runtime tasks is a criterion too.>

## Documentation invariants

- <Short statements that must stay true in the workflow, decision records, AGENTS.md.>

## Open questions and risks

- <risk and the rule that must not stay implicit>

## Related

- [`02-task-sequence.md`](../02-task-sequence.md)
````

Short form, for a [leaf task](../../task-layout/SKILL.md#proportion) with no hard signal:
frontmatter, heading and status lines, Goal, Plan and invariants (the constraints), Scope,
Acceptance criteria (each names its command), Related. Under Goal name the files to start from.
Visual work also names its design reference there (a file, an image or a URL), or says that
there is none and the brief is the measure.

Inline mark next to the place a delegated step arises:

```md
> **subagent-ready S01.** Run a subagent for this item and return its result before the next
> step.
> **Task:** <one atomic result> · **Context:** <3–7 files> · **Allowed changes:** <paths or
> "analysis only"> · **Check:** <command> · **Next:** <which step waits for the result> ·
> **Parallel:** <yes | after Sxx>.
```
