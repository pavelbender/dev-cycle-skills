---
name: cycle
description: >-
  Route a feature through the development cycle without invoking each skill by hand: detect
  the bundle's current stage from its files and frontmatter, run the next skill
  (plan-scenarios → plan-feature → write-task passes draft/detail/slices/validation →
  run-bundle → tidy-folder) and stop only at gates that need the user. Accepts a free-text
  intent or a bundle path. Use when asked to drive, continue or finish a feature end to end
  ("drive the cycle", "next step for the bundle", «доведи фичу до задач», «продолжи цикл»,
  «пройди весь цикл»).
argument-hint: "<intent | bundle-dir> [--until <stage>] [--no-stop]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Drive the development cycle

Input: a bundle directory, or a free-text intent when no bundle exists — then propose
`<tasks_root>/<domain>/<feature-slug>` from the project profile and the domain layout, and
confirm it (gate) before stage 1. Options: `--until <stage>` stops after that stage;
`--no-stop` skips confirmation gates (owner questions still stop). Claude Code passes
`$ARGUMENTS`; Codex the request text.

| # | Stage | Done when | Next skill |
| --- | --- | --- | --- |
| 1 | scenarios | `00-interaction-scenarios.md` exists; skipped when the intent names no screen, page or CLI flow | `plan-scenarios` |
| 2 | workflow | `01-workflow.md` exists | `plan-feature <intent> workflow` |
| 3 | sequence | `02-task-sequence.md` has its main decomposition | `plan-feature <intent> sequence` |
| 4 | drafts | every `TNN` of the sequence has a `tasks/TNN-*.md` with the task heading | `write-task all draft` |
| 5 | detail | each task has `pass: detail` or later | `write-task TNN detail`, per task |
| 6 | slices | each task has `pass: slices` or later | `write-task TNN slices`, per task |
| 7 | validation | each task has `pass: validation` | `write-task TNN validation`, per task |
| 8 | execution | every task `done`/`validated`, evidence for every `PNN` | `run-bundle` |
| 9 | close | bundle in `_completed/`, bundle branch merged into the WIP branch | `tidy-folder` (via `run-bundle` phase 5) |

Without `pass:` infer it from sections present: current base → detail; subagent-ready items
→ slices; tests and result validity → validation. Without frontmatter: `status` from the
suffix, `blocked_by` from the sequence.

## How to run a skill from here

Read the sibling `../<name>/SKILL.md` and follow it with the arguments in the table. This
works in every host; Claude Code may also invoke skills that allow model invocation directly.
Never paraphrase a skill from memory.

## Loop

1. Detect the stage: list the bundle, read task frontmatter, compare with the table. Say the
   stage in one line in the user's language.
2. Run the next skill to its end, including its own quality gate and report.
3. Re-detect. Advanced → continue; not advanced → stop and say what blocked.
4. Stop at a gate or at `--until`.

## Gates

Always stop, even with `--no-stop`:

- bundle path for a new intent;
- topic choice (`write-task` phase 0 without a `TNN`);
- a blocking owner question (open decisions or questions marked as blocking);
- replan signal or failed validation from `run-bundle`.

Stop unless `--no-stop`:

- before stage 8: batch plan, branches, worktrees;
- before merging the bundle branch into the WIP branch.

## Rules

- One stage per skill pass; never skip a stage because the next "would cover it".
- Never two write-heavy skills at once in one tree; parallelism only inside `run-bundle`.
- Layout, IDs, frontmatter and profile come from [`task-layout`](../task-layout/SKILL.md).
- Language: summaries and decisions in the user's language, agent-facing detail in compact
  English.

## Report

At each stop: current stage, files produced in this run, the gate reached and the input
needed, and how to continue (`cycle <bundle>`).
