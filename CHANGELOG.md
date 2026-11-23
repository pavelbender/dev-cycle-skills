# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the version is below 1.0, a
minor version may change behaviour; such changes are listed under **Changed** and
**Removed**, with the steps to take under **Upgrade notes**.

## [Unreleased]

## [0.7.0] - 2026-11-23

Test runs, file renames and coordinator waiting stop eating the wall clock. Source: thirteen
run reports from one product, reviewed by a consilium. The reports
show repeated full suites (17 full API runs, 222 machine-minutes in one bundle), polling loops
(97 minutes in another), about 15 link conflicts from `_DONE`/`_VAL` renames in one bundle,
and a coordinator turn that ended with work open.

### Added

- **`signals:` in the task frontmatter.** The hard signals of a task, set once by `write-task`
  and read by every later stage. `[]` means none: short route, short task form, no mutation
  drills, everyday-tier developer and QA. A list keeps the full route, mutation drills on the
  criteria it touches and a strong-tier QA. A missing field means hard.
- **Four more hard signals:** a redirect or untrusted input; concurrency or locks; deleting
  files outside the database; secrets or a rollout step.
- **Findings outside the task are one line** in the report, not an investigation. Visual work
  keeps at most two renders per width.
- **Test runs rules** in the delegation reference. Focused tests inside a task; a full package
  or suite only when a criterion names it or the task changes shared code; one full gate by
  the coordinator on the merged head; every run that backs a claim recorded with the commit
  SHA and the runner's summary line; no repeat of a run that is green on the same code; a long
  run is one background command and one wait; one test runner on a shared database.
- **Worktree hygiene line** for worker briefs: no `git stash`, a scratch directory of its own,
  stop a process only by a PID it started, unfiltered output when investigating a failure,
  `Edit` on CRLF files.
- **Grep before you change asserted behaviour.** `execute-task` and `fix` find every test and
  document that asserts the old value, by every spelling, before editing.

### Changed

- **A task file is never renamed.** Status lives only in the frontmatter; `_DONE` and `_VAL`
  are no longer written. Older files keep their suffix and are still read as that status.
- **Autopilot keeps data.** Choosing an option whose effect is to delete stored data is on the
  never-on-autopilot list: take the option that keeps it and list the skip.
- **`execute-task` and `fix` run `test` on the touched paths**, not on the whole package.
  `validate-task` cites the developer's green run on the same code instead of repeating it and
  checks a sample of the developer's mutation table.
- **`run-bundle` coordinator** no longer reruns a task's tests when the evidence holds a green
  run on unchanged code, and runs the full suites once at the close.
- **Coordinator rules apply with or without autopilot**: a message without a tool call ends the
  turn; "waiting on its own background work" notices are not returns; a return is relayed as a
  verdict line, the counts and the decisions it needs.
- **Returns are at most about 20 lines**; matrix and command output go to `evidence/`.

### Upgrade notes

- Put the slow packages of the project in the profile (`boundaries` or beside `test`) with
  their timeout flag, for example `go test -timeout 45m ./internal/seed`. Give a web `test`
  command a `{path}` so a focused run is possible.
- Nothing in a bundle under way needs a rewrite. Tasks without `signals:` are treated as
  hard until `write-task` sets it.

## [0.6.0] - 2026-11-18

Task files stop carrying records and numbers that go stale. Measured on a repeatable task from
a fixed checkout (three runs per variant): about 23% less spend per task, task file a quarter
shorter, acceptance checks unchanged.

### Changed

- **Records leave the task file.** Execution records go to `evidence/TNN-<slug>-run.md`,
  the validation matrix, commands and drift list to `evidence/TNN-<slug>-validation.md`. The
  task file keeps `status`, the `**Status:**` line and a link.
- **No line numbers or counts in a task file.** `write-task` principle 3 anchors to a symbol,
  never to `file:NNN`, and forbids counts of tests, files or output lines.
- **The task template is shorter.** The "Tests and validation" section is gone: every
  acceptance criterion names its own command. The implementation plan is at most ten lines.

### Added

- **`write-task/scripts/lint-task.sh`.** Flags `file:line` references, test and PASS counts,
  record sections and a task file over 20000 bytes. The `write-task` checklist runs it.

### Upgrade notes

- Task files already written keep their sections; nothing is rewritten.
- A project that read "Tests and validation" from task files by name reads the criteria instead.

## [0.5.1] - 2026-11-16

### Fixed

- **Autopilot no longer records its own choices as the owner's.** A decision made on
  `--auto` has Source `proposed` and names the observation that reopens it. Found on a
  pilot run where a font and a placeholder decision were written down as `owner`.

## [0.5.0] - 2026-11-15

The process is sized to the work, and visual work gets its own route.

### Added

- **`probe-paths` skill.** One call is one iteration: walks a few not-yet-covered scenarios
  on a live stand as different roles across every surface (web UI, API, CLI, TUI, local
  daemon, MCP server), runs subagents on concurrent-use edge cases, and records dead ends,
  missing reverse actions, UI/API permission mismatches, races and states with no way out.
  State lives in files, so `/loop` can repeat it. Finds and records only. New profile key
  `probe_notes`.
- **Visual work.** A task that names a design reference, or whose criteria judge a look, is
  planned as constraints and checks only. The developer renders the result early, compares
  it with the reference and improves it without an approval stop; the final screenshots go
  to `evidence/`. Screens that share one look are one task for one developer.
- **Decision source** in the workflow: `owner` or `proposed`. A proposed choice of stack,
  library or look names the observation that reopens it.

### Changed

- **The route is sized to the work.** `cycle` no longer runs every stage for every bundle.
  A hard signal (schema or migration, authorization, wire contract, stored data, more than
  one consumer) keeps the full route. Without one the planning passes run together:
  `plan-feature all`, then `write-task TNN all`.
- **A task file fixes constraints, not the implementation.** Code goes into a task only when
  another task or an outside consumer reads it, as a skeleton. The implementation plan is a
  suggestion: building it another way is not drift and needs no doc edit. A leaf task gets a
  short file.
- **No criterion on the exact diff or file set.** Scope is checked as "nothing changed
  outside the work areas".
- **Result validity is defined and bounded.** Negative controls and mutation drills only for
  criteria on a hard-signal path.
- **One commit per change of meaning.** Corrections a stage makes to neighbouring documents
  go into that stage's commit.

### Upgrade notes

- Bundles already under way keep the route their files show; nothing is re-planned.
- To get the previous behaviour for one bundle, ask `cycle` for the full plan.

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
