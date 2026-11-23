---
name: execute-task
description: >-
  Implement a development task from its task file: compare the task with current code,
  implement, test, update docs, set the status in the frontmatter. Use when asked to
  implement, execute or carry out a task file ("implement task", "execute T05", «реализуй
  задачу из», «выполни задание», «сделай T05»).
argument-hint: "<task-file-path>"
disable-model-invocation: true
user-invocable: false
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
   frontmatter, status.
4. The project glossary and decision records when the profile names them.
5. Code structure rules: [`coding-rules`](../coding-rules/SKILL.md) unless the project
   overrides them.

## Rules

- **Task file is a contract, not a fossil.** Code may have moved on. Find drift before editing.
  The contract is its [binding parts](../task-layout/SKILL.md#proportion); the implementation
  plan is a suggestion.
- **Fact beats document.** Read code and schemas first, then compare with the task text.
  Executable truth (migrations, schemas, tests) beats prose.
- **Architecture stays intact.** Reuse the package's patterns: repositories, services,
  migrations, schemas, tests, docs layout.
- **Findings outside the task are one line.** A defect you meet outside the work areas goes
  into the report as one line (path, symptom). Do not investigate it and do not fix it.
- **Docs are part of the result.** Behaviour changed → update workflow, decision records,
  local `AGENTS.md`, `02-task-sequence.md`.
- **One committer per tree: you.** Helpers do read-only research, isolated checks and the
  task's `SNN` items ([Delegation](#delegation)). Your own edits are single-threaded. Whole
  tasks run in parallel only in separate worktrees (`run-bundle`).

## Phase 1. Read the task, state the goal, plan

Extract: goal, in/out of scope, touched layers, contracts and schemas, acceptance criteria,
tests, documentation invariants, `blocked_by`.

Readiness: every code in `blocked_by` is `done`/`validated` or explicitly
accepted as an existing contract. Blocked → stop and report what blocks.

Restate the goal in 2–4 sentences. Ambiguous → ask before the first edit. As a subagent you
cannot ask: do the parts the question does not block, and return the question in your report.

Checklist: drift check → architecture read → implement → tests → criteria check → fixes →
re-check → format/lint/tests/smoke → docs → status.

## Phase 2. Compare the task with current code

For every task element find the real state. Use a code graph or language server when the
project has one; text search for literals, configs, docs and gaps. Send independent lookups
in one message so they run at the same time.

| Drift | Signal | Action |
| --- | --- | --- |
| Already done | code satisfies the item | no duplicate edit; go to criteria check |
| Partly done | some pieces exist | fill gaps, reuse |
| Done differently | same behaviour, other path/name/signature | use the real name, record drift |
| Code moved ahead | task contradicts current architecture | **stop**: list files and lines, propose a plan, get confirmation, update the task file; as a subagent return `Task needs replanning` with that list instead of asking |
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

- Run the profile's `format` and `lint` after edits, `test` on the paths you touched and
  their direct consumers. Not the whole package: follow the
  [Test runs](../task-layout/references/roles-and-models.md#test-runs) rules. Before you change
  behaviour that tests assert, grep those tests by every spelling of the old value and update
  them in the same pass.
- Schema or wire-contract changes only together with a decision record when the project keeps
  them.
- One acceptance criterion → one test where practical.
- Minimal diff; no whole-file rewrites without need.
- `SNN` items: do the contract and anything they depend on first, then hand the items to
  slice helpers ([Delegation](#delegation)) while you continue with the rest.
- The task turns out much bigger than its file says (many more files, several long
  verification loops): finish and commit a coherent part, then return `partial` with the list
  of what is left. A half-done task in one overloaded context is worse than two clean ones.

### Visual work

The task names a design reference, or its criteria judge how the result looks. A document
cannot settle a look, so get a rendered result early and improve it yourself:

1. Study the reference and the brief. Build the characteristic screen end to end first.
2. Render it with the profile's `stand` or the project's dev server. Take a screenshot at a
   phone width and at a desktop width, look at them, and compare them with the reference, or
   with the brief when there is no reference.
3. Adjust and render again until the screen holds up. Then build the other screens the same
   way. Keep at most two renders per width: the one you compared and the final one.

Composition, wording and styling are yours inside the binding parts. Iterating on them is
not drift and needs no task-file edit. Several screens touch more than five files: the
shared look is the justification `coding-rules` cs-011 asks for, not a reason to split the
task or return `partial`. Do not stop for approval after a render unless the
task says so or two binding requirements conflict. Save the final screenshots under
`evidence/` and list them in the report: the owner judges the look from them. When nothing
here can render the result, say so in the report and give the command that serves it; do not
claim the look was checked.

## Phase 5. Check every criterion

Per acceptance criterion: the code path that proves it; pass/fail; on difference — drift
class. Check documentation invariants, contracts (method, path, schema, errors, side
effects), failure scenarios.

Drift is **benign** (better current solution, invariants intact) or a **bug** (task,
architecture, invariant or practice broken). A broken invariant is never benign. Building it
another way than the implementation plan suggests is not drift: no record, no edit.

## Phase 6. Fix and repeat

Benign: keep code, reflect it in the binding parts of the task file, record why. Bug: fix
code or docs, rerun affected tests, back to phase 5. Exit when no unhandled drift remains.

## Phase 7. Verification

Smallest sufficient check first, then wider by risk: profile `format`, `lint`, `test {path}`;
the `stand` up and smoke commands when the task touches runtime. A full package or suite
only when a criterion names it or the task changes shared code, once, last; the coordinator
runs the full gate after the merge. Record each run that backs a claim in the run file with
the commit SHA, the command, the exit code and the runner's summary line. Quote failures verbatim:
command and output. Classify: implementation bug, stale test, stale task, environment problem
— then phase 6.

## Phase 8. Docs and status

1. Update docs to shipped behaviour: bundle workflow, `02-task-sequence.md` (task row),
   decision records, local `AGENTS.md`.
2. Task file: frontmatter `status` and the `**Status:**` line per
   [`task-layout`](../task-layout/SKILL.md). First implementation → `review` (awaits review) or
   `done` (no acceptance step); re-validation of completed work → `validated`.
3. Never rename the file: the status lives in the frontmatter only, so links to the task
   never break. (An older file that already carries `_DONE` or `_VAL` keeps its name.)
4. Last task of a fully closed bundle → the bundle moves to `_completed/` whole
   (`tidy-folder`); a partially closed bundle stays.
5. A closed `PNN` → `evidence/PNN-<slug>.md`: date, branch, `git rev-parse HEAD`, commands,
   observed result.
6. Do not append an execution record to the task file. Commands, results and drift go to
   `evidence/TNN-<slug>-run.md`; the task file keeps `status`, the `**Status:**` line and a
   link to that file.
7. Commit per [`task-layout`](../task-layout/SKILL.md#git-hygiene).

## Report

1. Task file path and its `status`.
2. Changed files: code, tests, docs.
3. Verification commands and results, verbatim on failure.
4. Benign drift reflected in the task.
5. Residual risks and what was not checked.
6. Branch, commits, worktree path; the branch to merge unless the caller merges it.
7. Questions and `needs consilium` items; `partial` with what is left, when unfinished.

Write it per [Reports](../task-layout/SKILL.md#reports).

## Delegation

When, how deep, which model and the brief format:
[delegation](../task-layout/references/roles-and-models.md). Your fan-out points:

- **Lookups and evidence** (phases 2–3): a researcher for a broad search or a large read you
  need only the conclusion of. A lookup whose target you know is a direct search.
- **Noisy runs** (phase 7): a helper runs a long suite and returns only the failures with
  their output.
- **`SNN` items** (phase 4): one slice helper per item, briefed from the item's row: context
  files, allowed changes, result, check. Items with `Parallel: yes` start in one message;
  the others wait for the item or plan step their `Parallel` cell names (`after S01`). Helpers
  do not commit. You review each patch, run
  `format`, `lint` and the tests over the whole change, and commit.
- No Agent tool, or the brief says "no helpers": do these steps yourself, in order.

A design question the task file does not decide and that spans several domains: return
`needs consilium: <question> · <domains> · <evidence paths>` and go on with the work that
does not depend on it. Only the main conversation convenes a
[`consilium`](../consilium/SKILL.md); when that is you, its three conditions decide.

## Anti-patterns

Implementing a stale task blindly. Skipping the architecture read. Calling a broken invariant
benign. Closing without tests. Leaving docs stale. Leaving a finished task with a stale `status`
or renaming the file to show it. Claiming "done" without command output.
