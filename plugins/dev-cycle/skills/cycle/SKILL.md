---
name: cycle
description: >-
  Route a feature through the development cycle: detect the bundle's current stage from its
  files and frontmatter, run the next stage (plan-scenarios → plan-feature → write-task
  passes draft/detail/slices/validation → run-bundle → tidy-folder) and stop only at gates
  that need the user. The single entry to every stage: accepts a free-text intent, a bundle
  path, or a request for one stage; --plan stops after planning, --task runs chosen tasks,
  --auto runs on autopilot with no questions. Use when asked to drive, continue or finish a
  feature, or to do one stage of it: plan scenarios or a feature, write or detail a task,
  implement or validate a task, run a bundle, tidy a docs folder ("drive the cycle", "next
  step for the bundle", "autopilot", "plan feature", "implement T05", "validate T07",
  «доведи фичу до задач», «продолжи цикл», «пройди весь цикл», «на автопилоте», «без
  вопросов», «спланируй фичу», «спланируй сценарии», «сформируй задание», «детализируй T05»,
  «реализуй задачу», «провалидируй задачу», «реализуй бандл», «приберись в папке»).
argument-hint: "<intent | bundle-dir> [--plan] [--task <TNN,…>] [--until <stage>] [--no-stop] [--auto]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Drive the development cycle

Input: a bundle directory, or a free-text intent when no bundle exists — then propose
`<tasks_root>/<domain>/<feature-slug>` from the project profile and the domain layout, and
confirm it (gate) before stage 1. Claude Code passes `$ARGUMENTS`; Codex the request text.

| Option | Effect |
| --- | --- |
| `--until <stage>` | stop after that stage |
| `--plan` | planning only: the same as `--until validation` |
| `--task <TNN,…>` | only these tasks: their missing planning passes, then execution and validation through `run-bundle --tasks`; no close stage. A task that is not ready ([readiness](../task-layout/SKILL.md#readiness)) is reported with what blocks it and is not started |
| `--no-stop` | skip confirmation gates; owner questions still stop |
| `--auto` | ask nothing at all, see [Autopilot](#autopilot); also "autopilot", «автопилот», «без вопросов» in the request |

The stage skills are not commands of their own: this skill is the entry to all of them. A
request for one stage in plain words runs that one skill and stops after it. Each runs in a
subagent with the role below (without subagents: read the skill and follow it yourself):

| Request | Run | Role | Tree |
| --- | --- | --- | --- |
| scenarios for a screen or a CLI flow | `plan-scenarios <feature>` | uiux expert | current |
| plan a feature, its workflow or its sequence | `plan-feature <intent> [workflow\|sequence]` | system architect | current |
| draft, detail, slice or polish a task | `write-task TNN <pass>` | solution architect; `validation` pass: QA developer | current |
| implement a task | `run-bundle --tasks TNN`: execution and validation only, no planning passes | you coordinate | a worktree per task |
| implement a task "here", without a worktree | `execute-task <task file>` | developer | current |
| validate a finished task | `validate-task <task file>` | QA developer | the tree that holds the task's work: its worktree or branch, else current |
| tidy a documentation folder | `tidy-folder <folder>` | release manager | current; any docs folder, no bundle needed |

A request that names a task as `TNN` without a bundle: the bundle is the one given earlier in
the conversation, or the only open bundle under `tasks_root` that has that ID; several
candidates → ask. A task's worktree is the one `git worktree list` shows for the profile's
`task_branch`.

A bug report (broken behaviour, an error text, a screenshot of a failure) goes to
[`fix`](../fix/SKILL.md), not through the stages. `fix` comes back here only when the cause
needs a planned change.

Check the result as the skill's own report describes, and commit state as in
[Rules](#rules).

| # | Stage | Done when | Next skill | Role |
| --- | --- | --- | --- | --- |
| 1 | scenarios | `00-interaction-scenarios.md` exists; skipped when the intent names no screen, page or CLI flow | `plan-scenarios` | uiux expert |
| 2 | workflow | `01-workflow.md` exists | `plan-feature <intent> workflow` | system architect |
| 3 | sequence | `02-task-sequence.md` has its main decomposition | `plan-feature <intent> sequence` | system architect |
| 4 | drafts | every `TNN` of the sequence has a `tasks/TNN-*.md` with the task heading | `write-task all draft` | solution architect |
| 5 | detail | each task has `pass: detail` or later | `write-task TNN detail slices`, per task: one agent runs both passes | solution architect |
| 6 | slices | each task has `pass: slices` or later | done by the stage 5 agent; `write-task TNN slices` only for a task that already has `pass: detail` | solution architect |
| 7 | validation | each task has `pass: validation` | `write-task TNN validation`, per task | QA developer |
| 8 | execution | every task `done`/`validated`, evidence for every `PNN` | `run-bundle` | you coordinate |
| 9 | close | bundle in `_completed/`, bundle branch merged into the WIP branch | `tidy-folder` (via `run-bundle` phase 5) | release manager |

Without `pass:` infer it from sections present: current base → detail; subagent-ready items
→ slices; tests and result validity → validation. Without frontmatter: `status` from the
suffix, `blocked_by` from the sequence.

## Route

The table is the full route. Size it per [proportion](../task-layout/SKILL.md#proportion)
before stage 1, and say the route and its signal in the line that proposes the bundle path.
On a bundle already under way, size it again from the signals for the tasks without `pass:`
and leave the tasks that have one as they are.

- **Full**: a hard signal, or a request for the full plan. Every stage runs for the tasks the
  signal touches. `--until draft`, `detail` or `slices` runs the passes one by one up to it.
  `--plan` and `--until validation` only set where to stop; they do not change the route.
- **Merged**: no hard signal. `plan-feature <intent> all` covers stages 2–3; `write-task TNN
  all` covers stages 4–7 in one context and ends at `pass: validation`, which is what the
  detector reads. Documents are sized to the work.
- **Visual work**: plan the constraints and the checks, then get to a rendered result;
  [`execute-task`](../execute-task/SKILL.md#visual-work) holds the loop. There is no approval
  stop after a render unless the user asked for one or two binding requirements conflict.
  At the merge gate show the screenshots from `evidence/`.

Every route keeps a stated goal, the constraints, the material decisions and a check of the
result. Name the route in each stage brief. The user can name another route; when the
signals name a heavier one, say so once.

## How to run a skill from here

You are the coordinator. [Delegation](../task-layout/references/roles-and-models.md) says
how: read it and the model notes before the first stage. Run each stage in a subagent with
the table's role and the model and effort the reference picks. Use its brief format: `READ
../<name>/SKILL.md` with the arguments from the table, the role, `MODE autopilot` when on.
Check the stage's "done when" yourself, then add the notes row. Without subagents read the
skill and follow it yourself. Follow the skill's text, not your memory of it.

Stages 1–4 run one agent at a time: each writes documents the next one reads.

Stages 5–7 run in waves, so the task files of a bundle are written in parallel:

- Stages 5–6: a wave is one layer of the `blocked_by` graph: the tasks whose predecessors
  are all in earlier waves. A task's detail reads the contracts in its predecessors' task
  files, so a wave starts after the previous one is committed. Example: T01 → T02, T01 → T03,
  T03 → T04, and T05, T06 independent gives {T01, T05, T06}, then {T02, T03}, then {T04}.
- Stage 7: all tasks together form a single wave.
- Start a wave in one message. Run at most 5 agents at once; a larger wave goes in groups of
  5.
- Stages 5 and 6 share one agent per task: both passes need the same reading of the code, so
  a second agent would only read it again. With `--until detail` pass `detail` alone.
- In a wave each agent writes only its own task file and does not commit (`COMMIT do not
  commit: the parent commits`). It returns changes it needs in `02-task-sequence.md` as
  exact row text. After the wave you check each "done when", apply the row changes, and
  commit the wave's files by path.
- A single task, or a host without subagents: no wave, the agent commits its own file.

## Loop

1. Detect the stage: run `bash ../task-layout/scripts/bundle-status.sh <bundle>` (the path is
   relative to this file). On Windows run it in Git Bash: in Claude Code that is the Bash tool;
   the `bash` that PowerShell finds is WSL and cannot see the path. It prints the planning files, one row per task, the proof points,
   the dependency waves and the stage. Without bash: list the bundle, read task frontmatter,
   compare with the table. A task without `pass:` needs your reading of its sections, as
   described under the table. Say the stage in one line in the user's language.
2. Run the next skill to its end, including its own quality gate and report.
3. Re-detect. Advanced → continue; not advanced → stop and say what blocked.
4. Stop at a gate or at `--until`.

A stage report that carries `needs consilium`, or a blocking open decision that is technical
and spans several domains: check the three conditions of
[`consilium`](../consilium/SKILL.md). They hold → convene it before the gate; the gate then
shows the owner the consilium's record instead of a bare question. They do not hold → settle
it by the cheaper steps of
[hard questions](../task-layout/references/roles-and-models.md#hard-questions) (evidence,
then the advisor when the host has one); what is still open is an ordinary gate question.

## Gates

Always stop, even with `--no-stop` (with `--auto` none of these asks, see Autopilot):

- bundle path for a new intent, with the [route](#route);
- topic choice (`write-task` phase 0 without a `TNN`);
- a blocking owner question (open decisions or questions marked as blocking);
- replan signal or failed validation from `run-bundle`.

Stop unless `--no-stop`:

- before stage 8: batch plan, branches, worktrees;
- before merging the bundle branch into the WIP branch.

With `--no-stop` start `run-bundle` as an uninterrupted run, so it skips these two as well.
`--no-stop` removes the question, not a ban: when the caller forbids a step (an unattended
job never merges into the WIP branch), skip that step and report it.

## Autopilot

`--auto`: nobody answers. Never ask, never wait for confirmation: decide, record, continue.
Implies `--no-stop`. The table below overrides every ask in the skills you run from here.
Run `run-bundle` as `AUTOPILOT` (an uninterrupted run); it passes the rule to its workers.

A message without a tool call ends your turn, and on autopilot nobody restarts it. A status
note is welcome, but it goes in the same message as the next tool call. Do not end a turn on
a summary that announces the next stage, on an offer to continue, or because a stage is a
good place to report: start the next stage.

| Where a gate or skill would ask | Autopilot decision |
| --- | --- |
| bundle path for a new intent | the proposed path |
| route | the one the signals name; unclear → full |
| topic choice | the recommended topic |
| ambiguous goal, several candidate files | the reading most consistent with the bundle's accepted documents |
| blocking owner question, open decision | the option the document recommends; a technical question with no recommendation that meets the three conditions of [`consilium`](../consilium/SKILL.md) → convene it, its result is the choice; else the smallest reversible one that keeps existing contracts and data |
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

- Run the [route](#route) you sized. Do not drop a check because a later stage "would cover
  it".
- One committer per tree. Parallel writers only as the waves above and `run-bundle` allow:
  each owns its own files, and shared documents have one writer.
- Layout, IDs, frontmatter and profile come from [`task-layout`](../task-layout/SKILL.md).
- Every stage ends committed per [`task-layout`](../task-layout/SKILL.md#git-hygiene),
  before the next stage and before any gate or question. Corrections a stage makes to
  neighbouring documents go into that stage's commit.
- Language: summaries and decisions in the user's language, agent-facing detail in compact
  English.

## Report

At each stop: current stage, files produced in this run, the gate reached and the input
needed, and how to continue (`cycle <bundle>`). Add role, model and effort per stage, and
the consilium records of this run. Autopilot adds "Autopilot decisions" (file, question,
choice, one line each) and the skipped never-on-autopilot steps. Write it per
[Reports](../task-layout/SKILL.md#reports).
