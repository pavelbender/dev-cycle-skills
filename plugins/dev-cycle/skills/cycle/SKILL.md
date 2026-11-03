---
name: cycle
description: >-
  Route a feature through the development cycle without invoking each skill by hand: detect
  the bundle's current stage from its files and frontmatter, run the next skill
  (plan-scenarios → plan-feature → write-task passes draft/detail/slices/validation →
  run-bundle → tidy-folder) and stop only at gates that need the user. Accepts a free-text
  intent or a bundle path; --auto runs it on autopilot with no questions. Use when asked to
  drive, continue or finish a feature end to end ("drive the cycle", "next step for the
  bundle", "autopilot", «доведи фичу до задач», «продолжи цикл», «пройди весь цикл»,
  «на автопилоте», «без вопросов»).
argument-hint: "<intent | bundle-dir> [--until <stage>] [--no-stop] [--auto]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Drive the development cycle

Input: a bundle directory, or a free-text intent when no bundle exists — then propose
`<tasks_root>/<domain>/<feature-slug>` from the project profile and the domain layout, and
confirm it (gate) before stage 1. Options: `--until <stage>` stops after that stage;
`--no-stop` skips confirmation gates (owner questions still stop); `--auto` (or "autopilot",
«автопилот», «без вопросов» in the request) asks nothing at all, see [Autopilot](#autopilot).
Claude Code passes `$ARGUMENTS`; Codex the request text.

| # | Stage | Done when | Next skill | Role |
| --- | --- | --- | --- | --- |
| 1 | scenarios | `00-interaction-scenarios.md` exists; skipped when the intent names no screen, page or CLI flow | `plan-scenarios` | uiux expert |
| 2 | workflow | `01-workflow.md` exists | `plan-feature <intent> workflow` | system architect |
| 3 | sequence | `02-task-sequence.md` has its main decomposition | `plan-feature <intent> sequence` | system architect |
| 4 | drafts | every `TNN` of the sequence has a `tasks/TNN-*.md` with the task heading | `write-task all draft` | solution architect |
| 5 | detail | each task has `pass: detail` or later | `write-task TNN detail`, per task | solution architect |
| 6 | slices | each task has `pass: slices` or later | `write-task TNN slices`, per task | solution architect |
| 7 | validation | each task has `pass: validation` | `write-task TNN validation`, per task | QA developer |
| 8 | execution | every task `done`/`validated`, evidence for every `PNN` | `run-bundle` | you coordinate |
| 9 | close | bundle in `_completed/`, bundle branch merged into the WIP branch | `tidy-folder` (via `run-bundle` phase 5) | release manager |

Without `pass:` infer it from sections present: current base → detail; subagent-ready items
→ slices; tests and result validity → validation. Without frontmatter: `status` from the
suffix, `blocked_by` from the sequence.

## How to run a skill from here

You are the coordinator ([roles and models](../task-layout/references/roles-and-models.md)): read the model
notes, then run each stage in a subagent with the table's role and the model and effort the
reference picks. Brief: `READ ../<name>/SKILL.md`, the arguments from the table, the role,
`AUTOPILOT` when on, "return questions, do not ask", "commit your files". Check the stage's
"done when" yourself, then add the notes row. Without subagents read the skill and follow it
yourself. Never paraphrase a skill from memory.

## Loop

1. Detect the stage: list the bundle, read task frontmatter, compare with the table. Say the
   stage in one line in the user's language.
2. Run the next skill to its end, including its own quality gate and report.
3. Re-detect. Advanced → continue; not advanced → stop and say what blocked.
4. Stop at a gate or at `--until`.

## Gates

Always stop, even with `--no-stop` (with `--auto` none of these asks, see Autopilot):

- bundle path for a new intent;
- topic choice (`write-task` phase 0 without a `TNN`);
- a blocking owner question (open decisions or questions marked as blocking);
- replan signal or failed validation from `run-bundle`.

Stop unless `--no-stop`:

- before stage 8: batch plan, branches, worktrees;
- before merging the bundle branch into the WIP branch.

## Autopilot

`--auto`: nobody answers. Never ask, never wait for confirmation: decide, record, continue.
Implies `--no-stop`. The table below overrides every ask in the skills you run from here.
Run `run-bundle` as `AUTOPILOT` (an uninterrupted run); it passes the rule to its workers.

| Where a gate or skill would ask | Autopilot decision |
| --- | --- |
| bundle path for a new intent | the proposed path |
| topic choice | the recommended topic |
| ambiguous goal, several candidate files | the reading most consistent with the bundle's accepted documents |
| blocking owner question, open decision | the option the document recommends; else the smallest reversible one that keeps existing contracts and data |
| batch plan, merge into the WIP branch | proceed |
| task left in `review` | the worker's `validate-task` verdict is the acceptance: `validated`, `_VAL` |
| replan signal, "code moved ahead" | `write-task TNN` passes detail, slices, validation from the worker's file-and-line list, then rerun the task; a second signal on the same task ends the run |

Record each decision where its question was: under the document's decisions as
`autopilot: <choice> — <reason>`, the question removed from open questions.

Never on autopilot, whatever the documents say: push, deploy, release, package publishing,
production, secrets, credentials, deleting customer data, editing an applied migration. Skip
that step, list it in the report, continue with the rest.

The run ends (with the report, still no question) only when it cannot move forward:
validation or a merge conflict failing twice, a second replan signal on a task, a blocker
outside the repository (missing credentials, unreachable service).

Unlike the scheduled jobs (`agent-jobs/common.md`), autopilot does not stop with
`needs-owner`: the user who starts it chose decisions after the fact over questions.

## Rules

- One stage per skill pass; never skip a stage because the next "would cover it".
- Never two write-heavy skills at once in one tree; parallelism only inside `run-bundle`.
- Layout, IDs, frontmatter and profile come from [`task-layout`](../task-layout/SKILL.md).
- Every stage ends committed per [`task-layout`](../task-layout/SKILL.md#git-hygiene),
  before the next stage and before any gate or question.
- Language: summaries and decisions in the user's language, agent-facing detail in compact
  English.

## Report

At each stop: current stage, files produced in this run, the gate reached and the input
needed, and how to continue (`cycle <bundle>`). Add role, model and effort per stage.
Autopilot adds "Autopilot decisions" (file,
question, choice, one line each) and the skipped never-on-autopilot steps.
