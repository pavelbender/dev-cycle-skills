---
name: run-bundle
description: >-
  Coordinate the execution of a feature bundle: pick ready tasks from 02-task-sequence.md and
  frontmatter, run each through execute-task and validate-task in its own git worktree
  (sequentially, or in parallel when tasks touch disjoint code), merge validated work into the
  bundle branch, and the bundle branch into the WIP branch at the end. Use when asked to
  implement a whole bundle or several tasks ("run the bundle", "implement T03–T06",
  «реализуй бандл», «выполни цикл до конца»).
argument-hint: "<bundle-dir-or-02-task-sequence.md> [sequential|parallel] [--into <branch>]"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Run a bundle: execute, validate, merge

Input: a bundle directory or its `02-task-sequence.md`; optional mode (`sequential` default,
`parallel` only for tasks with disjoint work areas); optional target branch (`--into`,
default: the profile's `bundle_branch`, created from `wip_branch` with its own worktree when
missing). Claude Code passes `$ARGUMENTS`; Codex the request text.

You are the coordinator. You do not edit code or task files yourself: workers do, one per
task, each in its own worktree. Returning worktree content into the target branch is your
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
- One writer per tree. Parallelism exists only between worktrees.

## Phase 1. Status map

Read `02-task-sequence.md` and every `tasks/TNN-*.md`. Without frontmatter: `status` from the
suffix, `blocked_by` from the sequence's `Depends on`. Table:

```text
ID | file | status | blocked_by | ready? | work areas (packages/dirs from Scope and Changes by layer) | PNN
```

Ready = every code in `blocked_by` is `done`/`validated`. A task in `review` blocks its
dependants until accepted; say so. Tasks with blocking open decisions are not started: report
them.

## Phase 2. Batch

Sequential: the next ready task in graph order. Parallel: ready tasks whose work areas are
pairwise disjoint; shared files (route tables, layout shells, registries, the migrations
directory, `02-task-sequence.md` rows) count as overlap and force sequential order.

Announce the batch, branches, worktrees and stands. Wait for confirmation unless the user
asked for an uninterrupted run (`AUTOPILOT` from `cycle --auto` is one).

## Phase 3. Per task

1. Create the worktree and branch; run setup.
2. Brief two workers in turn, each a fresh subagent in that worktree (without subagents run
   both steps yourself, one task at a time). Role, model and effort per
   [roles and models](../task-layout/references/roles-and-models.md); read its model notes first.

   ```text
   ROLE    developer, <model>, <effort>
   WORKDIR <worktree path>
   READ    <skills dir>/execute-task/SKILL.md
   DO      <task file path>
   COMMIT  one logical change; do not push; return questions, do not ask; report task status, files, commands with output, residual risks
   ```

   After the developer returns, the QA developer validates independently:

   ```text
   ROLE    QA developer, <model>, <effort>
   WORKDIR <worktree path>
   READ    <skills dir>/validate-task/SKILL.md
   DO      <task file path after rename>
   COMMIT  fixes, status and evidence; do not push; return questions, do not ask; report the verdict line, criteria matrix, commands with output
   ```

   To both briefs add the profile's `boundaries` line and the owner decisions relevant to the
   task. On `AUTOPILOT` add:

   ```text
   MODE    autopilot: never ask or wait; where a skill says ask or confirm, take the recommended
           option, record it in the task file as `autopilot: <choice> — <reason>`, continue;
           "code moved ahead" → return a replan signal; finish validated (_VAL), not review
   ```

3. On return check yourself: task file renamed and `status` matches the suffix; the verdict is
   one of the two `Task validated` lines; `git status --short` is clean; profile `format` and
   `lint` are clean; the tests the task names pass when you rerun them. A failure goes back to
   the worker with the exact output; a second failure stops the run. Add a model notes row
   per worker.
4. Replan signal (`Task needs replanning`, major drift) → stop that task, keep the worktree,
   report the worker's file-and-line list. No merge.

## Phase 4. Merge into the bundle branch

In the target branch's worktree: `git merge --no-ff <task_branch>`, then `format`, `lint` and
the task's tests again. Resolve only trivial conflicts (link paths, sequence rows); code
conflicts go back to the worker. Then: update the sequence row if needed, remove the task
worktree, stop its stand. Dependants become ready after the merge, not after the report.

## Phase 5. Close

All tasks `done`/`validated` and every `PNN` has an `evidence/` report → `tidy-folder` on the
bundle (to `_completed/`), update the domain README, then merge the bundle branch into
`wip_branch` with `--no-ff`, rerun checks. This last merge is a gate: ask unless the user
asked for an uninterrupted run. Pushing follows the project's rules; never on `AUTOPILOT`.
A partially closed bundle stays in place and unmerged.

## Stop conditions

A blocking owner question; validation failing twice; a replan signal; a code conflict at
merge; a worker editing outside its task's work areas. Each stop names the task, the evidence
and the decision needed. On `AUTOPILOT` a replan signal and a blocking question follow
[`cycle`](../cycle/SKILL.md#autopilot) instead of stopping.

## Report

After each task and at the end: task, branch, merge commit, verdict line, commands with
results, residual risks; status-map delta; what is ready next.
