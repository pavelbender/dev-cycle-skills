# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the version is below 1.0, a
minor version may change behaviour; such changes are listed under **Changed** and
**Removed**, with the steps to take under **Upgrade notes**.

## [0.4.0] - 2026-11-12

The plugin is tuned for Claude Fable 5.2, Opus 5.5, Sonnet 5.5 and Haiku 5.5, and reduced to
four commands.

### Added

- **`fix` skill.** Takes a bug report in any form (a sentence, a screenshot, a log, a
  failing test), reproduces the defect and finds the root cause, then chooses the path from
  the cause: a direct fix with a regression test, a briefed developer in a worktree with an
  independent check, or a planned change through `cycle`. The path moves up when the fix
  grows and down when the cause proves small. `--diagnose` reports the cause without a fix.

- **`consilium` skill.** Four or five read-only role agents study one hard cross-domain
  question independently, challenge each other in one round, and the chair records the
  decision with the dissent.
- **`automation` skill.** Sets up, retimes, pauses or removes all four scheduled agents in one
  pass: profile check, timing plan, dry runs, install in the order in which the collectors
  feed the workers. Every action also takes one agent, and `run <job>` starts one run now,
  outside the schedule.
- **Schedule intervals.** `--every` (`-Every` on Windows) for the scheduled agents: `30m`,
  `60m`, `2h` and other intervals that divide an hour or a day. A reinstall without the
  option keeps the interval and the start time.
- **Model and effort per scheduled agent.** Collectors run on `sonnet` at `high`,
  `autodebug` on `opus` at `high`, `autobacklog` on `opus` at `medium`; `--model` and
  `--effort` override them at install.
- **Delegation reference.** One document for when to delegate and what it costs, subagent
  layers, unit size, parallel work, the brief format, roles, and how each current Claude
  model behaves.
- **`cycle --plan` and `cycle --task <TNN,…>`**, and single-stage requests in plain words
  ("validate T07", "tidy docs/tasks/billing").
- **Read-only agent types** for Claude Code: `dev-cycle:researcher` and
  `dev-cycle:consilium-member`, limited to reading and searching.
- **`bundle-status.sh`.** Prints the status map of a bundle, the dependency waves of its
  unfinished tasks and the current stage, from the sequence and the task frontmatter.
- **Planning in waves.** Task files with no dependency between them are written in parallel;
  the detail and slices passes of a task share one agent.
- **`Work areas` per task** in the task sequence, and a `Parallel` column for subagent-ready
  items in a task file.
- **Reports section** in the layout contract: a report is written for a reader who has not
  seen the work.
- **Tests** for the scheduled-agent runner (bash and PowerShell) and for the status script.
- **`docs/anthropic/README.md`**: which statement of Anthropic's prompting guides each part
  of the plugin applies.

### Changed

- **`run-bundle` runs ready tasks in parallel by default** when their work areas are
  disjoint, at most five at a time. `sequential` restores one task at a time.
- **The QA developer starts at `high` effort**; every subagent call now names its model and
  effort explicitly.
- **A developer under `run-bundle` sets `done` and the `_DONE` suffix**; acceptance is the
  independent validation that follows.
- **`--no-stop` also skips the merge gate inside `run-bundle`.** A caller's ban on a step
  still holds.
- **Slice helpers may write in parallel in one tree** when their files are disjoint; the
  parent commits.
- **`coding-rules` is worded as plain imperatives.** The rule IDs `cs-001`…`cs-028` and
  their meaning are unchanged.
- **A dry run keeps the state directory out of `git status`**, so it can be made before
  install.
- **Project job notes can no longer relax a hard rule** of the unattended runs, except where
  the rule says so itself.
- **`process-diagram-convention.md`** is rewritten in neutral terms and linked directly from
  `plan-feature`.

### Removed

- **The stage skills as commands.** `plan-scenarios`, `plan-feature`, `write-task`,
  `execute-task`, `validate-task`, `run-bundle`, `tidy-folder` and `task-layout` are no
  longer listed or invoked directly; `cycle` reads them. `coding-rules` still loads on its
  own when the agent writes code.
- **The skills `autodebug`, `autobacklog`, `collect-issues` and `collect-backlog`.** The
  jobs themselves stay: their texts moved to `agent-jobs/jobs/`, and `automation` manages
  them.

### Upgrade notes

- Replace `/dev-cycle:<stage>` calls with `/dev-cycle:cycle` and a request in plain words,
  `--plan` or `--task`.
- Replace `/dev-cycle:<job> install` with `/dev-cycle:automation install --jobs <job>`.
- The first run of each installed scheduled agent after the update fails once and writes no
  ledger row: the installed runner updates itself during that run and works from the next
  one.
- Scheduled agents installed with an earlier version keep `opus` at `medium`, because their
  scheduler entry names the model. Reinstall them through `automation` to get the per-agent
  models.

## [0.3.0] - 2026-11-04

### Added

- **`cycle --auto`.** An autopilot that asks nothing: it takes the recommended option at
  every gate, records each decision where its question was, and never pushes, deploys or
  touches production.
- **Coordinator roles** (system architect, solution architect, UI/UX expert, developer, QA
  developer, researcher, release manager) with a model tier per role, for Claude Code and
  Codex.
- **Model notes.** A per-project record of which model and effort worked for which role and
  task kind; observed results override the starting values.
- **Git hygiene rule** for every skill that writes files: logical commits, only the files
  the skill changed, no turn ended with uncommitted work.

## [0.2.0] - 2026-11-02

### Added

- **Unattended scheduled agents**: `autodebug`, `autobacklog`, `collect-issues` and
  `collect-backlog`, each working on one item per run in its own worktree and branch, with a
  report and a ledger.
- **Runners** for Windows Task Scheduler (`agent-job.ps1`) and for cron on Linux and macOS
  (`agent-job.sh`).

### Fixed

- Job state ledgers that were committed by mistake are no longer tracked.

## [0.1.0] - 2026-10-29

### Added

- The first release: the skills `cycle`, `plan-scenarios`, `plan-feature`, `write-task`,
  `execute-task`, `validate-task`, `run-bundle`, `tidy-folder`, and the contracts
  `task-layout` and `coding-rules`.
- Plugin packaging and marketplace catalogs for Claude Code and Codex.
