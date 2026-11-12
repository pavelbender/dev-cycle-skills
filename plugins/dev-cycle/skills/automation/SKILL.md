---
name: automation
description: >-
  Set up and manage the scheduled unattended jobs of the dev-cycle plugin for the current
  repository, all in one pass or one by one: check the project profile, plan the intervals
  and start times so that the collectors feed the workers, dry-run each job, install
  collect-issues, collect-backlog, autodebug and autobacklog in that order, and hand the
  daily routine to the owner. Also status, pause, resume, a new interval, or removal. Use
  when asked to set up, schedule or retime the plugin's automations («настрой
  автоматизации», «поставь все джобы», «поставь autodebug», «автобэклог», «сборщик known
  issues», «расписание каждые 60 минут», "set up dev-cycle automation").
argument-hint: "install [--work 30m] [--collect 6h] [--jobs <job,…>] [--no-dry-run] | dry-run <job> | run <job> | status | pause [<job>] | resume [<job>] | uninstall [<job>]"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Automation: all scheduled jobs in one pass

Input: an action and its options. Claude Code passes `$ARGUMENTS`. The jobs run Claude Code,
so this skill is for Claude Code only.

| Option | Meaning | Default |
| --- | --- | --- |
| `--work <interval>` | how often `autodebug` and `autobacklog` start | `30m` |
| `--collect <interval>` | how often `collect-issues` and `collect-backlog` start | `6h` |
| `--jobs <job,…>` | install only these jobs | all four the profile allows |
| `--no-dry-run` | skip the dry runs of phases 4 and 5 | dry runs are made |

A request in plain words carries the same options: "workers every hour, collectors twice a
day" is `--work 60m --collect 12h`.

## The four jobs

| Order | Job | What one run does | Reads | Writes |
| --- | --- | --- | --- | --- |
| 1 | `collect-issues` | finds untracked defects and adds them to the known-issues file | documents, job reports, code markers | branch `collect/known-issues` |
| 2 | `collect-backlog` | finds deferred and undone work and adds it to the backlog | documents, bundles, job reports | branch `collect/backlog` |
| 3 | `autodebug` | fixes one known issue | the known-issues file and the collector branch | a `fix/…` branch, a report |
| 4 | `autobacklog` | advances one backlog item | the backlog and the collector branch | a `bl/…` or bundle branch, a report |

The collectors feed the workers: a worker reads its collector's branch before the owner
merges it. That is why the collectors are installed first. No job pushes or merges into
`wip_branch`; the owner reviews the reports and merges the branches. Rules of a run:
[`../../agent-jobs/common.md`](../../agent-jobs/common.md). What each job picks and how it
finishes: `../../agent-jobs/jobs/<job>.md`. The prompt of a run is the run header, the common
rules, the job file and the project's job notes, in that order.

Each job runs on its own pinned model and effort, so a changed default in the user's settings
does not reach it:

| Job | Model, effort | Why |
| --- | --- | --- |
| `collect-issues`, `collect-backlog` | `sonnet`, `high` | they read and write documents; a long scan in which every candidate is checked against the code |
| `autodebug` | `opus`, `high` | a bug in existing code: checking the edge cases is the work |
| `autobacklog` | `opus`, `medium` | scoped work from a task file; it also coordinates `cycle` |

## Timing

Intervals are written as minutes or hours: `30m`, `60m`, `2h`; a plain number is minutes, and
`60m` is the same as `1h`.
The scheduler needs an even repeat, so an interval is a divisor of an hour (`5m`, `10m`,
`15m`, `20m`, `30m`) or whole hours that divide a day (`1h`, `2h`, `3h`, `4h`, `6h`, `8h`,
`12h`, `24h`). Anything else is refused by the script; offer the nearest allowed value.

The script places the start times itself; pass `--minute` or `--hour` only when the user
names a time.

| Job | Start times at the default intervals | Rule |
| --- | --- | --- |
| `collect-issues` | 00:00, 06:00, 12:00, 18:00 | starts at the top of its interval |
| `collect-backlog` | 03:00, 09:00, 15:00, 21:00 | half an interval after `collect-issues` |
| `autodebug` | :07 and :37 of every hour | workers start off the hour, so they do not start with a collector |
| `autobacklog` | :22 and :52 of every hour | 15 minutes after the other worker |

The worker times in the table hold when no other repository on the machine has worker jobs.
The script counts the workers already scheduled and moves a new one to a free slot, so read
the real start times from the install output and from `status`, not from this table.

How to choose the intervals with the user:

- A worker run is one full agent session of up to 2 hours; then the process is killed. A run
  that is still going makes the next start of the same job skip, so a short interval never
  stacks runs. It only decides how soon the next item starts.
- At most 2 worker runs are active on the machine at once, over all repositories
  (`--max-agents`). The collectors are not counted.
- `30m` suits a machine that is free and a long list of items. `60m` suits a machine the
  owner also works on. `2h`–`6h` gives a slow, cheap drip. Each start costs tokens even when
  it ends with `no-candidate`.
- The collectors need not run more often than the owner merges their branches or the workers
  empty the lists: `6h` for an active repository, `12h` or `24h` for a quiet one. A collector
  interval shorter than the worker interval adds cost and no work.

## Install

Seven phases, in this order. Each phase finishes before the next one starts.

### Phase 1. Preconditions

- You are at the root of the target repository (`git rev-parse --show-toplevel`).
- The dev-cycle plugin is installed for Claude Code. The jobs run the installed copy of the
  plugin, not a working copy of its repository.
- The scheduler exists: Task Scheduler with PowerShell 7 on Windows, `crontab` on Linux and
  macOS. `claude` is on `PATH`.
- Say this to the user in plain words before anything is installed: the jobs run with
  `--permission-mode bypassPermissions`, so every command the agent decides to run executes
  as the user without a prompt. Install only where that is acceptable.

### Phase 2. Profile

Read the `## Dev cycle` section of the root `AGENTS.md` or `CLAUDE.md`
([`task-layout`](../task-layout/SKILL.md#project-profile)).

| Key | Needed by | When it is missing |
| --- | --- | --- |
| `format`, `lint`, `test` | `autodebug`, `autobacklog` | ask for the commands and add them to the profile; without them the workers are not installed |
| `known_issues` | `collect-issues` (required), `autodebug` (optional) | `collect-issues` is left out; `autodebug` is still installed and works only from recent evidence follow-ups. Offer to create the file and the key |
| `backlog` | `collect-backlog` (required), `autobacklog` (optional) | `collect-backlog` is left out; `autobacklog` is still installed and scans open bundles under `tasks_root`. Offer to create the file and the key |
| `wip_branch`, `worktree_root`, `worktree_setup` | all | the defaults of `task-layout` apply; say which |
| `jobs_state` | all | default `.dev-cycle/jobs/`; the script adds it to `.git/info/exclude` |
| `job_notes` | all | offer it when the project has live environments, stands, or items a job must skip |

Profile edits are the user's files: show the lines, apply them when the user agrees, commit
per [`task-layout`](../task-layout/SKILL.md#git-hygiene).

### Phase 3. Plan

Build the plan from the options and the profile, and show it as one table: job, interval,
start times, what it reads, where it writes, and the jobs left out with the reason. Check the
existing jobs first (`status`): a job that is already installed keeps its interval and start
time unless the user gave a new interval.

Ask once for a go-ahead that covers the plan and the permission mode of phase 1. Do not
install anything before the answer.

### Phase 4. Collectors

For each collector in the plan, `collect-issues` first:

1. Unless `--no-dry-run`: start its dry run in the background. The two collectors can run at
   the same time. A dry run lists candidates and creates no branch and no commit; it writes
   only under `jobs_state`, which the script keeps out of `git status`. When it ends, read
   its report (`<jobs_state>/<job>/reports/`) with the user: are the candidates real, is
   anything collected that the job notes should exclude.
2. Install it with the collector interval.

### Phase 5. Workers

For each worker in the plan, `autodebug` first:

1. Unless `--no-dry-run`: start its dry run in the background; both workers can run at the
   same time. A dry run takes 10–30 minutes, picks an item and stops. Read the report with
   the user: is the pick one the owner would allow unattended.
2. Install it with the worker interval.

A pick the user rejects is a reason to add a line to the job notes, not to drop the job.

A dry run that ends at once with no report was skipped: two worker runs were already active
on the machine. `<jobs_state>/<job>/logs/skipped.log` says so. Wait for one to finish and
start the dry run again.

### Phase 6. Verify

Run `status`. Every planned job is listed as active with the interval of the plan. Tell the
user the next start time of each job.

### Phase 7. Hand over

Tell the user the routine the jobs expect from the owner:

- `status` shows the last ledger rows of each job. Reports are in
  `<jobs_state>/<job>/reports/`, logs and skipped starts in `<jobs_state>/<job>/logs/`.
- Merge `collect/known-issues` and `collect/backlog` when their items are right:
  `git merge --no-ff <branch>` from the `wip_branch` checkout. Until then only the jobs see
  the new items.
- Review and merge the `fix/…` and `bl/…` branches the same way. A report ends with the
  merge command.
- A row with `needs-owner` waits for an answer; `blocked` names what the machine could not
  reach.
- `pause` before a large manual refactoring or a rebase of `wip_branch`, `resume` after it.

## Commands

`<plugin>` is this plugin's root, two levels above this file. Run from the repository root.

| Step | Windows | Linux, macOS |
| --- | --- | --- |
| dry run | `pwsh -NoProfile -File <plugin>/agent-jobs/agent-job.ps1 -Action run -Job <job> -DryRun` | `<plugin>/agent-jobs/agent-job.sh run <job> --dry-run` |
| one run now | `… -Action run -Job <job>` | `… run <job>` |
| install | `pwsh -NoProfile -File <plugin>/agent-jobs/agent-job.ps1 -Action install -Job <job> -Every <interval>` | `<plugin>/agent-jobs/agent-job.sh install <job> --every <interval>` |
| status | `… -Action status` | `… status` |
| pause, resume | `… -Action pause`, `… -Action resume` | `… pause`, `… resume` |
| uninstall | `… -Action uninstall` | `… uninstall` |

For a job that is already installed and keeps its interval, leave out `-Every` / `--every`:
the script then keeps the interval and the start time. With the option the start time is
placed again.

`pause`, `resume` and `uninstall` without a job act on all jobs of this repository. With
`-Job <job>` or a job name they act on one. `-Model`, `-Effort` (`--model`, `--effort`) at
install replace a job's model and effort from the table above; pass them only when the user
asks. A job installed without them follows the table, also after a plugin update.

## Other actions

- **One job**: `install --jobs <job>` runs the same seven phases for that job alone.
  `dry-run <job>` only starts its dry run and reads the report with the user.
- **run `<job>`**: one real run of that job now, outside the schedule; the job does not have
  to be installed. It works as a scheduled run does: its own worktree and branch, a report,
  a ledger row. Read the report with the user.
- **status**: run it and report per job: active or paused, interval, next start, the last
  ledger rows. Name the jobs that are not installed.
- **pause**, **resume**: all jobs of this repository, or the ones the user names.
- **A new interval**: install the job again with the new `-Every` / `--every`. The start time
  is placed again; state, ledgers and branches stay.
- **uninstall**: removes the scheduler entries. State, reports and branches stay; say where
  they are.

## Report

In the user's language, per [Reports](../task-layout/SKILL.md#reports): the jobs installed
with interval and next start, the jobs left out and why, what the dry runs picked, profile
lines added, and the owner's routine of phase 7.
