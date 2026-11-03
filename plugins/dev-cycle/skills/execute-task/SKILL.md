---
name: execute-task
description: >-
  Implement a development task from its task file: compare the task with current code,
  implement, test, update docs, set the status and the _DONE/_VAL suffix. Use when asked to
  implement, execute or carry out a task file ("implement task", "execute T05", «реализуй
  задачу из», «выполни задание», «сделай T05»).
argument-hint: "<task-file-path>"
metadata:
  contract: ../task-layout/SKILL.md
---

# Execute a task file

Input: path to the task file (`<tasks_root>/<domain>/<bundle>/tasks/TNN-<slug>.md`). Claude
Code passes it as `$ARGUMENTS`; Codex in the request text. No path → ask, do not guess.

Output: code, tests and docs that satisfy the task, and the task file with the right status.
The task is not closed until every phase below has passed.

## Language

User-facing text (status line, summaries, decisions, open questions, the final report) in the
user's language. Agent-facing detail (drift tables, file lists, commands, verification
matrices) in compact English. Identifiers, paths, commands and error text verbatim.

## Context

1. Root `AGENTS.md` and its `## Dev cycle` profile ([`task-layout`](../task-layout/SKILL.md)):
   commands, forbidden zones, tasks root, decisions location.
2. Nearest local `AGENTS.md` for every file you edit; it overrides the root one.
3. The layout contract [`task-layout`](../task-layout/SKILL.md): bundle layout, IDs,
   frontmatter, suffixes.
4. The project glossary and decision records when the profile names them.
5. Code structure rules: [`coding-rules`](../coding-rules/SKILL.md) unless the project
   overrides them.

## Rules

- **Task file is a contract, not a fossil.** Code may have moved on. Find drift before editing.
- **Fact beats document.** Read code and schemas first, then compare with the task text.
  Executable truth (migrations, schemas, tests) beats prose.
- **Architecture stays intact.** Reuse the package's patterns: repositories, services,
  migrations, schemas, tests, docs layout.
- **Docs are part of the result.** Behaviour changed → update workflow, decision records,
  local `AGENTS.md`, `02-task-sequence.md`.
- **One writer per tree.** Subagents only for read-only research and isolated checks; edits
  single-threaded. Parallel work happens in separate worktrees (`run-bundle`).

## Phase 1. Read the task, state the goal, plan

Extract: goal, in/out of scope, touched layers, contracts and schemas, acceptance criteria,
tests, documentation invariants, `blocked_by`.

Readiness: every code in `blocked_by` is `done`/`validated` (or `_DONE`/`_VAL`) or explicitly
accepted as an existing contract. Blocked → stop and report what blocks.

Restate the goal in 2–4 sentences. Ambiguous → ask before the first edit.

Checklist: drift check → architecture read → implement → tests → criteria check → fixes →
re-check → format/lint/tests/smoke → docs → status and rename.

## Phase 2. Compare the task with current code

For every task element find the real state. Use a code graph or language server when the
project has one; text search for literals, configs, docs and gaps.

| Drift | Signal | Action |
| --- | --- | --- |
| Already done | code satisfies the item | no duplicate edit; go to criteria check |
| Partly done | some pieces exist | fill gaps, reuse |
| Done differently | same behaviour, other path/name/signature | use the real name, record drift |
| Code moved ahead | task contradicts current architecture | **stop**: list files and lines, propose a plan, get confirmation, update the task file |
| No drift | task matches the baseline | continue |

Minor drift: record and continue with real names.

## Phase 3. Read the architecture of the touched area

Only what is relevant: package `AGENTS.md`, decision records and schemas of the component,
nearest modules, tests and fixtures, the project's known-issues list if it has one.

Before editing name: modules and contracts touched; patterns reused; side effects (DB, files,
containers, network); tests that will prove the result.

## Phase 4. Implement

Typical order: contract (types, schemas, migration) → logic → adapter (CLI, API, job) →
tests → docs. A vertical slice with one test before broad edits.

- Run the profile's `format` and `lint` after edits, `test` for the touched package.
- Schema or wire-contract changes only together with a decision record when the project keeps
  them.
- One acceptance criterion → one test where practical.
- Minimal diff; no whole-file rewrites without need.

## Phase 5. Check every criterion

Per acceptance criterion: the code path that proves it; pass/fail; on difference — drift
class. Check documentation invariants, contracts (method, path, schema, errors, side
effects), failure scenarios.

Drift is **benign** (better current solution, invariants intact) or a **bug** (task,
architecture, invariant or practice broken). A broken invariant is never benign.

## Phase 6. Fix and repeat

Benign: keep code, reflect it in the task file, record why. Bug: fix code or docs, rerun
affected tests, back to phase 5. Exit when no unhandled drift remains.

## Phase 7. Verification

Smallest sufficient check first, then wider by risk: profile `format`, `lint`, `test {path}`;
the `stand` up and smoke commands when the task touches runtime. Quote failures verbatim:
command and output. Classify: implementation bug, stale test, stale task, environment problem
— then phase 6.

## Phase 8. Docs and status

1. Update docs to shipped behaviour: bundle workflow, `02-task-sequence.md` (task row, file
   path after rename), decision records, local `AGENTS.md`.
2. Task file: frontmatter `status` and the `**Status:**` line per
   [`task-layout`](../task-layout/SKILL.md). First implementation → `review` (awaits review) or
   `done` (no acceptance step); re-validation of completed work → `validated`.
3. Rename: `<name>.md` → `<name>_DONE.md` on `done`; → `_VAL` on `validated`. One suffix,
   never a chain. Update every link to the file.
4. Last task of a fully closed bundle → the bundle moves to `_completed/` whole
   (`tidy-folder`); a partially closed bundle stays.
5. A closed `PNN` → `evidence/PNN-<slug>.md`: date, branch, `git rev-parse HEAD`, commands,
   observed result.
6. Commit per [`task-layout`](../task-layout/SKILL.md#git-hygiene).

## Report

1. Task file path after rename and its `status`.
2. Changed files: code, tests, docs.
3. Verification commands and results, verbatim on failure.
4. Benign drift reflected in the task.
5. Residual risks and what was not checked.
6. Branch, commits, worktree path; the branch to merge unless the caller merges it.

## Delegation

A subagent pays off when the subtask is independent and would otherwise flood the context
(search, logs, test runs), or can run in parallel. Do not delegate what needs most of your
context or frequent back-and-forth. Brief: goal, exact files, forbidden actions, done
criterion, return format, budget, and the profile's `boundaries` line if set. Role, model and
effort per [roles and models](../task-layout/references/roles-and-models.md) (usually researcher, light tier).

## Anti-patterns

Implementing a stale task blindly. Skipping the architecture read. Calling a broken invariant
benign. Closing without tests. Leaving docs stale. Leaving a finished task without a suffix or
with a suffix chain. Claiming "done" without command output.
