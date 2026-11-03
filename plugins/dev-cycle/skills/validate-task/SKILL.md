---
name: validate-task
description: >-
  Validate a completed development task against its task file: check every acceptance
  criterion with proof from code, tests and commands, classify each drift as benign or bug,
  check failure paths, fix or escalate, set status validated and the _VAL suffix. Use when
  asked to validate, verify, accept or review a completed task («провалидируй задачу»,
  «проверь выполненное», «приёмка T07», "validate T07").
argument-hint: "<task-file-path> [diff|branch|commit]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Validate a completed task

Input: path to the task file; when available also the changed-file list, a diff, branch or
commit. Claude Code passes arguments as `$ARGUMENTS`; Codex in the request text.

No explicit target → find the last unambiguously completed task in the current thread (task
file reference, "implemented" claim, rename to `_DONE`). One candidate → take it and say why
the choice is unambiguous. Several or none → ask. Never invent a task file or substitute a
"similar-looking" one.

## Role

You are the validator. No claim without evidence. The verdict is built from code, schemas,
tests, configs, docs and command output. The job is not new work but a proven answer: does the
result satisfy the task file?

## Language

Verdict, drift list, residual risks and anything the user reads in the user's language.
Validation matrix, proof paths, commands in compact English. Identifiers and errors verbatim.

## Context

Root `AGENTS.md` and its `## Dev cycle` profile, nearest local `AGENTS.md`,
[`task-layout`](../task-layout/SKILL.md) (frontmatter, suffixes), decision records and glossary
when the profile names them. Executable truth (migrations, schemas, tests) beats prose: on
conflict the schema wins.

## Rules

1. Criteria are checked one by one. There is no "looks good overall" verdict.
2. A criterion passes only when code, test, schema, command or observable behaviour proves it.
3. Every difference gets a label: benign deviation or bug.
4. Benign must be proved. "It is an improvement" is not proof.
5. A bug demands action: fix, or stop for replan when the task file is stale.
6. Re-validation after fixes is mandatory.
7. Failure paths matter as much as the happy path.

## Phase 1. Extract checks

From the task file: goal, scope, acceptance criteria, documentation invariants, contracts
(CLI, API, schemas, migrations, zones), tests section, result-validity section.

Turn each criterion into questions: what in the code guarantees it; which contract
participates; which test or command proves it; what behaviour is observable. Split a broad
criterion into 2–5 atomic checks.

Validation matrix (initial status `not checked`):

| ID | Check | Task source | Expected behaviour | Where proof lives | Status |
| --- | --- | --- | --- | --- | --- |

## Phase 2. Gather facts

Find real implementation points: models and migrations, services, CLI/API, schemas, jobs,
tests, docs. Read targeted; a diff is not enough when a neighbouring guard, service or caller
controls behaviour. Use a code graph or language server when the
project has one; text search for literals and docs.

Derived artefacts (OpenAPI documents, generated clients, published schemas) are compared with
their source: a mismatch is a bug.

Test coverage by meaning: does a test prove the criterion directly or indirectly; does it cover
the failure path; if there is no test, can the criterion be proved by code plus a command, and
is that enough.

## Phase 3. Check criteria one by one

Per criterion: exact code path; flow `input → check → logic → result`; executable proof (test,
command, smoke). Status is one of three:

- **passed** — enough proof, behaviour matches;
- **passed with deviation** — satisfied, but path, name, signature or flow differs;
- **failed** — no proof, or behaviour contradicts the task.

Record files checked, what proves the status, which command ran.

## Phase 4. Benign or bug

Benign only when **all** hold: task goal preserved; no criterion weakened; architecture
pattern intact; data flow correct; invariants of data, statuses, transactions, links intact;
failure handling no worse than expected; no hidden regression in contracts, migrations, docs;
the difference is a rename, clarification, simplification or improvement, not a loss of
behaviour.

Bug when any holds: criterion missing or partial; documentation invariant broken; contract
mismatch changes behaviour; check, validation or error handling weakened; path changed without
a doc update; tests missing or contradicting fact; the difference cannot be defended by the
current architecture.

Proof not crisp → bug or replan. Benign is never the default.

## Phase 5. Failure paths

For relevant criteria: invalid input, missing entity, state conflict, repeated action, lost
lease or interrupted run, races when the task implies them.

A failure is correct when: the reason is expected; no inconsistent state remains; the error
surfaces in the right layer and format (exit code, HTTP status, job outcome); the user never
sees false success; the error text leaks nothing extra. Silent partial success is a bug.

## Phase 6. Fix and repeat

Benign: keep code, align the task file with real behaviour, record why. Bug: fix at the root
cause (code, test, artefact, doc); if the root is a stale task file, do not patch blindly, stop
for replan. After any fix re-check criteria, invariants, contracts, failure paths and commands
of the touched slice.

After code edits run the profile's `format` and `lint`.

## Phase 7. Status and report

On "matches" (with or without fixes): frontmatter `status: validated`, `**Status:**` line with
date and link to the evidence, rename to `_VAL` (from `_DONE`, or from no suffix when
acceptance and validation coincide), links updated. Proof of a `PNN` goes to
`evidence/PNN-<slug>.md`.

Exactly one verdict:

- `Task validated: matches task file.`
- `Task validated: matches task file after fixes.`
- `Task not validated: bugs remain.`
- `Task needs replanning: task file stale vs current code.`

Then: criteria matrix (text, status, proof, drift class); drift list split into benign and
bugs with the action (kept / fixed / needs replan); failure paths checked; commands run and
not run with reasons; residual risks (stand not raised, criterion proved by code without a
dedicated test, …). Fixes, status and evidence are committed per [`task-layout`](../task-layout/SKILL.md#git-hygiene); name the
branch and commits.

## Checklist

- [ ] Every criterion checked separately with proof.
- [ ] Every drift classified; benign proved against phase 4 conditions.
- [ ] Bugs fixed or escalated to replan.
- [ ] Invariants, contracts, failure paths checked.
- [ ] Re-validation after fixes done.
- [ ] Status, suffix and links updated; verdict unambiguous.
