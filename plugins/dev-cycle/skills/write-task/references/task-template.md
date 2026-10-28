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

<Schemas, signatures, migrations, file formats, outcomes — skeletons, not implementation.>

## Changes by layer

### Data and models

### Service / CLI / API

### UI

### Contracts, schemas, docs

## Access

| Operation or element | Permission | Who | On denial | Test |
| --- | --- | --- | --- | --- |

## Subagent-ready work items

| ID | Where | Why delegate | Context | Allowed changes | Result | Check | Before |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S01 | Tests | focused test for criterion N without the whole context | `<3–7 files>` | tests only | patch | `<test command>` | implementation |

## Invariants and failure semantics

<What stays true; how the system fails: exit codes, HTTP statuses, job outcomes, no partial
state.>

## Implementation plan

1. contract → 2. logic → 3. adapter → 4. tests → 5. docs

## Acceptance criteria

1. <One checkable case: command, test or UI action, expected result.>

## Tests and validation

- `<test command {path}>` — <what it proves>
- <smoke on the stand when the task touches runtime>

## Documentation invariants

- <Short statements that must stay true in the workflow, decision records, AGENTS.md.>

## Open questions and risks

- <risk and the rule that must not stay implicit>

## Related

- [`02-task-sequence.md`](../02-task-sequence.md)
````

Inline mark next to the place a delegated step arises:

```md
> **subagent-ready S01.** Run a subagent for this item and return its result before the next
> step.
> **Task:** <one atomic result> · **Context:** <3–7 files> · **Allowed changes:** <paths or
> "analysis only"> · **Check:** <command> · **Next:** <which step waits for the result>.
```
