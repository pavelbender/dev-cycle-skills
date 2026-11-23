---
name: run-bundle
description: >-
  Coordinate the execution of a feature bundle: pick ready tasks from 02-task-sequence.md and
  frontmatter, run each through execute-task and validate-task in its own git worktree
  (in parallel when tasks touch disjoint code, otherwise in sequence), merge validated work into the
  bundle branch, and the bundle branch into the WIP branch at the end. Use when asked to
  implement a whole bundle or several tasks ("run the bundle", "implement T03–T06",
  «реализуй бандл», «выполни цикл до конца»).
argument-hint: "<bundle-dir-or-02-task-sequence.md> [auto|sequential] [--tasks <TNN,…>] [--into <branch>]"
disable-model-invocation: true
user-invocable: false
metadata:
  contract: ../task-layout/SKILL.md
---

# Run a bundle: execute, validate, merge

Input: a bundle directory or its `02-task-sequence.md`; optional mode (`auto` default:
ready tasks with disjoint work areas run in parallel, the rest one at a time; `sequential`:
always one at a time; `parallel` is accepted as `auto`); optional `--tasks <TNN,…>` to run
only those tasks and skip phase 5; optional target branch (`--into`,
default: the profile's `bundle_branch`, created from `wip_branch` with its own worktree when
missing). Claude Code passes `$ARGUMENTS`; Codex the request text.

You are the coordinator; [delegation](../task-layout/references/roles-and-models.md) says
how, so read it and the model notes first. You do not edit code or task files yourself:
workers do, one per task, each in its own worktree. Returning worktree content into the target branch is your
job; the user does not process PRs. Progress notes and the final report in the user's
language; worker briefs and status tables in compact English.

Branch names, worktree location, setup, format/lint/test and stand commands come from the
project profile ([`task-layout`](../task-layout/SKILL.md#project-profile)).

## Conventions

- Worktree per task: `<worktree_root>/<task_branch with / → ->`, branch `task_branch` from the
  target branch.
- Fresh worktree: run `worktree_setup` when the profile has it. Lockfiles that are gitignored
  are copied from the main worktree first and installed in frozen mode, so every worktree
  resolves the same versions.
- A task that touches runtime gets its own stand when the profile defines `stand`; take it
  down before removing the worktree.
- One committer per tree: the task's developer, then its QA developer. Tasks run in parallel
  only in separate worktrees. Inside a worktree the developer may run slice helpers as
  [parallel work](../task-layout/references/roles-and-models.md#parallel-work) allows.

## Phase 1. Status map

Run `bash ../task-layout/scripts/bundle-status.sh <bundle>` (the path is relative to this
file; on Windows in Git Bash, which is the Bash tool of Claude Code): it prints this table from `02-task-sequence.md` and the task frontmatter. Without
bash, read `02-task-sequence.md` and every `tasks/TNN-*.md` yourself; without frontmatter:
`status` from the suffix of an older file, else `formed`; `blocked_by` from the sequence's `Depends on`. Table:

```text
ID | file | status | blocked_by | ready? | work areas (packages/dirs from Scope and Changes by layer) | PNN
```

Ready = every code in `blocked_by` is `done`/`validated`. A task in `review` blocks its
dependants until accepted; say so. Tasks with blocking open decisions are not started: report
them.

## Phase 2. Batch

The batch is the largest set of ready tasks whose work areas are pairwise disjoint, at most
5, and fewer when each needs its own stand. Shared files (route tables, layout shells,
registries, the migrations directory, `02-task-sequence.md` rows) count as overlap: of two
overlapping tasks the earlier in graph order goes first and the other waits for the next
batch. Work areas come from the sequence's `Work areas` line when it has one, else from the
task file's Scope and Changes by layer. One ready task, or mode `sequential`: a batch of one.

Announce the batch, branches, worktrees and stands. Wait for confirmation unless the user
asked for an uninterrupted run (`AUTOPILOT` from `cycle --auto` is one).

## Phase 3. Per task

1. Create the worktree and branch; run setup.
2. Brief two workers in turn, each a fresh subagent in that worktree (without subagents run
   both steps yourself, one task at a time). Role, model, effort and the brief format per
   [delegation](../task-layout/references/roles-and-models.md#brief), with its "keep
   working" and "real check" lines.

   ```text
   ROLE     developer; <model>, <effort>
   GOAL     implement the task so that every acceptance criterion passes
   READ     <skills dir>/execute-task/SKILL.md <task file path>
   WORKDIR  <worktree path>
   SCOPE    the task's work areas; out of scope: other tasks' files, anything the task does not name
   RULES    <boundaries line>; <owner decisions for this task>; do not push
   HELPERS  helpers allowed, 2 layers left: SNN items and read-only lookups
   DONE     task file `status: done`, file not renamed; format, lint and the task's tests pass; tree clean
   RETURN   task status, files, commands with output, residual risks, questions, `needs consilium`; `partial` with what is left
   COMMIT   your files, in logical commits, before you return
   ```

   After the developer returns, the QA developer validates independently. A fresh agent
   sees the result without the developer's assumptions:

   ```text
   ROLE     QA developer; <model>, <effort>
   GOAL     prove or disprove that the result satisfies the task file
   READ     <skills dir>/validate-task/SKILL.md <task file path>
   WORKDIR  <worktree path>
   SCOPE    fixes inside the task's work areas, the task file, evidence
   RULES    <boundaries line>; <owner decisions for this task>; do not push
   HELPERS  helpers allowed, 2 layers left: read-only checks per criterion, noisy test runs
   DONE     one verdict line; `status` matches it; tree clean
   RETURN   the verdict line, criteria matrix, commands with output, questions, `needs consilium`
   COMMIT   fixes, status and evidence before you return
   ```

   Both briefs carry the Test runs line of the
   [delegation](../task-layout/references/roles-and-models.md#brief) and, in a parallel batch,
   "focused tests, type-check and lint only; no full suite".

   In a parallel batch start all developers in one message. Start a task's QA developer as
   soon as its developer returns; do not wait for the rest of the batch.

   On `AUTOPILOT` add:

   ```text
   MODE    autopilot: never ask or wait; where a skill says ask or confirm, take the recommended
           option, record it in the task file as `autopilot: <choice> — <reason>`, continue;
           "code moved ahead" → return a replan signal; finish `validated`, not review
   ```

3. On return check yourself: the task file keeps its name and its `status` matches the verdict; the verdict is
   one of the two `Task validated` lines; `git status --short` is clean; profile `format` and
   `lint` are clean; the evidence records the task's tests green with a commit SHA and a
   summary line, and the code paths are unchanged since (`git diff --quiet <sha> HEAD --
   <code paths>`). Rerun the task's tests yourself only when that record is missing or
   stale. A failure goes back to the worker with the exact output; a second failure stops that task. Add a model notes row
   per worker.
4. `partial` from a developer → brief a fresh developer in the same worktree with the list of
   what is left, one step up in effort or tier. A second `partial` on the same task means the
   task is too big: stop it and report a split proposal for the sequence.
5. Replan signal (`Task needs replanning`, major drift) → stop that task, keep the worktree,
   report the worker's file-and-line list. No merge.
6. `needs consilium` in a report → check the three conditions of
   [`consilium`](../consilium/SKILL.md). They hold → convene it, give the record to the
   worker and continue the task. They do not hold → settle the question by evidence or the
   advisor and give the worker the answer; an owner decision is a blocking owner question.
   The other tasks of the batch keep running.

## Phase 4. Merge into the bundle branch

In the target branch's worktree: `git merge --no-ff <task_branch>`, then `format`, `lint` and
the task's own tests again, not the full suite. Merge one task at a time, in graph order. Resolve only trivial
conflicts (link paths, sequence rows); code conflicts go back to the worker. Then: update the sequence row if needed, remove the task
worktree, stop its stand. Dependants become ready after the merge, not after the report.

## Phase 5. Close

All tasks `done`/`validated` and every `PNN` has an `evidence/` report → `tidy-folder` on the
bundle (to `_completed/`), update the domain README, then merge the bundle branch into
`wip_branch` with `--no-ff`, rerun checks. This is where the full suites run, once on the
merged head, as one background command ([Test runs](../task-layout/references/roles-and-models.md#test-runs)).
This last merge is a gate: ask unless the user
asked for an uninterrupted run. Pushing follows the project's rules; never on `AUTOPILOT`.
A partially closed bundle stays in place and unmerged.

## Stop conditions

A blocking owner question; validation failing twice; a replan signal; a code conflict at
merge; a worker editing outside its task's work areas. A stop holds that task and its
dependants; the independent tasks of the batch finish and merge first. Each stop names the
task, the evidence and the decision needed. On `AUTOPILOT` a replan signal and a blocking question follow
[`cycle`](../cycle/SKILL.md#autopilot) instead of stopping.

## Report

After each task and at the end: task, branch, merge commit, verdict line, commands with
results, residual risks; status-map delta; what is ready next; role, model and effort per
worker. Write it per [Reports](../task-layout/SKILL.md#reports).
