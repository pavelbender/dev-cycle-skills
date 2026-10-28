---
name: write-task
description: >-
  Write or refine a development task file in a feature bundle, in one of four passes: draft
  (bounded stub), detail (sections verified against code), slices (subagent-ready SNN items),
  validation (acceptance criteria and test commands polished). Builds the status map from the
  task sequence and frontmatter, proposes topics when none is chosen. Use when asked to form,
  draft, detail or refine a task ("draft task T05", "detail T05", "what task next",
  «сформируй задание», «детализируй T05», «выдели подзадачи для субагентов»).
argument-hint: "[TNN|all] [draft|detail|slices|validation|all]"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Write a task file

You are the architect. You write no code and edit no existing code. The result is a task file
in the repository; the chat gets only the path and a summary. Layout, IDs, frontmatter, project
profile: [`task-layout`](../task-layout/SKILL.md). File structure:
[`references/task-template.md`](references/task-template.md).

Arguments (`$ARGUMENTS` in Claude Code, request text in Codex): a task ID or `all` (every
formed task of the bundle) and a pass. No ID → phase 0 proposes topics. No pass → `all`.

## Passes

| Pass | Phases | Writes |
| --- | --- | --- |
| `draft` | 0, 1, 6 (stub) | frontmatter, Goal, Scope, Acceptance criteria as one-line stubs, Related. Bounded, nothing verified against code yet. |
| `detail` | 1–4, 6 | every relevant section verified against code: current base, target contract, changes by layer, invariants, plan |
| `slices` | 5 | Subagent-ready work items (`SNN`) and inline marks; nothing else changes |
| `validation` | 6 (criteria, tests) | one case per criterion, exact test and verification commands, result validity, documentation invariants |
| `all` | 0–7 | everything at once |

Each pass edits the file in place, keeps earlier content and never renumbers IDs. After a pass
set frontmatter `pass:` to the highest pass applied (`draft` < `detail` < `slices` <
`validation`); `cycle` reads it.

## Language

What the user reads — Goal, Open decisions, Open questions and risks, the chat summary — in the
user's language. Everything agent-facing — current base, target contract, changes by layer,
plan, `SNN` items, criteria mechanics, test commands — in compact English. Keep the section
headings a bundle already uses.

## Principles

1. **Fact beats document.** The sequence card and the workflow may lag the code. `git log`,
   diffs and file reads first, then comparison; discrepancies stated explicitly.
2. **Out-of-scope is a contract.** Every deferred item of the predecessors gets a decision:
   include, keep out, include partially — one-line reason and a link.
3. **Exact paths.** Paths, modules, commands, schema names from the actual repository, never
   copied from the card blindly.
4. **One criterion, one checkable case.** Verified by one command, test or UI action. "Works
   correctly" is not a criterion.
5. **Reuse patterns.** Migrations, repositories, services, fixtures, test layout come from the
   predecessors and the local `AGENTS.md`.
6. **Access up front.** For every operation, command and UI element: who may, which
   permission, behaviour on denial.
7. **Subagent-ready explicit.** Atomic steps with small context and their own check get
   `SNN`; none → say so.
8. **Subagents make no architectural decisions.** Delegate mechanical steps: tests for a ready
   criterion, one repository method, path checks, evidence packs. Never what needs the whole
   document or changes scope, contract or schema.
9. **Minimal sufficiency.** Groundwork "for later" only when the task cannot work without it.

## Phase 0. Status map and topic choice

Read the root `AGENTS.md` with its profile, the domain `README.md`, then the bundle's
`02-task-sequence.md`. Classify files per the layout contract.

Status map: `ID | file | status | blocked_by | ready/blocked | out-of-scope items`. Readiness
comes from `blocked_by`/`Depends on`, never from file numbers. Compare with code: a `_DONE`
task without implementation and a formed task whose result already ships are discrepancies.

No topic chosen → propose 3–5 as a table: name, status (`formed` / `new` / `revise`),
reference docs, `TASK_ID` from the sequence, predecessors with commits, what gets built, why
now, risk. Priority: ready formed tasks without implementation → out-of-scope of done tasks →
uncovered entities and screens → the user's own topic. Recommend one and ask. Phase 1 only
after the answer. A formed file is refined in place, never duplicated.

## Phase 1. Reference documents

Bundle workflow, decision records and schemas of the component, package `AGENTS.md`, glossary.
Record: touched layers, invariants, owner decisions, permissions per action.

## Phase 2. Predecessors

For each code in `blocked_by`: its task file, `git log --oneline -1 <ref>`,
`git show --stat <ref>`, diff when needed. What really appeared: modules, migrations,
schemas, commands, tests. Note discrepancies with the predecessors' text.

## Phase 3. Card vs repository

Per card element, its code state: models and migrations, services, CLI/API and their
published contracts, schemas, storage, UI routes, tests and fixtures. The table "exists /
missing / create / extend" goes into "Current base and dependencies".

## Phase 4. Predecessors' out-of-scope

Walk "Out of scope" of the bundle's done tasks; decide per item: include, keep out, include
partially — with reason and link. Do not re-list what already ships.

## Phase 5. Subagent-ready

Mark a step `SNN` only when: one clear result (patch, evidence, command output); 3–7 files of
context; inputs already stated in the document; no product or architecture decisions; local
verification. Format in the template. No candidates → "None: the task needs one owner and the
whole context."

## Phase 6. Write the file

Path: `<bundle>/tasks/TNN-<slug>.md`, `TNN` from `02-task-sequence.md`. Frontmatter per the
contract: `id`, `status: formed`, `blocked_by`, `blocks` required; `milestone`, tracker link
optional; `assigned_to` only with more than one contributor. Sections per the template; empty
ones are omitted or say "Not required" with a reason. Then update the task row in
`02-task-sequence.md` with the exact path.

Checklist: ID and path match the sequence; `blocked_by` = `Depends on`; no duplicate of a
formed file; every contract has a data flow and an access rule; every criterion has a test or
command; every out-of-scope item has reason and link; paths verified; `SNN` atomic and tied
to a criterion; invariants agree with decision records and schemas.

## Phase 7. Reply

File path; 3–5 line summary (name, bundle, in scope, deferred); the hand-over line:

```text
Implement the task in <path>. Meet every acceptance criterion and test.
```

Never paste the full task into the chat.

## Anti-patterns

Skipping topic choice when none is given. Picking a task by file number. Continuing a global
`NN`. Duplicating an existing formed task. Copying the card blindly. Inventing a new pattern
instead of the accepted one. Marking everything subagent-ready. Leaving a subagent without
boundaries. Compound criteria. Unnoticed code discrepancies.
