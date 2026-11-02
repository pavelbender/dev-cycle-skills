---
name: collect-backlog
description: >-
  Scheduled unattended agent that walks the repository's documents, task bundles and job
  reports for work explicitly described as deferred, not done, postponed or planned for the
  future, checks that it is still current and not done, and adds it to the project's backlog
  on a rolling branch that autobacklog also reads. Install, dry-run, pause, resume, check or
  remove the scheduler job (Windows Task Scheduler, cron on Linux and macOS) for the current repository. Use when asked to set up
  or manage automatic backlog collection («сборщик задач для backlog», «поставь
  collect-backlog», "schedule collect-backlog").
argument-hint: "install [-Hour N | --hour N] | dry-run | status | pause | resume | uninstall"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Collect backlog

Every 6 hours (by default at 03:00, 09:00, 15:00, 21:00) a headless Claude Code agent reads
what changed since its last run, finds work that documents defer or leave undone, proves it
is still current, and adds it to the `backlog` file on the branch `collect/backlog`.
`autobacklog` reads that branch too and can take a collected item into the dev cycle before
the owner merges it. Rules shared with the other jobs:
[`../../agent-jobs/common.md`](../../agent-jobs/common.md).

## Operator

Run from the target repository root; `<plugin>` is this plugin's root (two levels above
this file). The job runs Claude Code. Windows uses `agent-job.ps1` (PowerShell 7, Task
Scheduler); Linux and macOS use `agent-job.sh` (bash, cron) with `--minute N`, `--hour N`,
`--dry-run` instead of `-Minute N`, `-Hour N`, `-DryRun`.

| Argument | Windows | Linux, macOS |
| --- | --- | --- |
| `install` | `pwsh -NoProfile -File <plugin>/agent-jobs/agent-job.ps1 -Action install -Job collect-backlog [-Hour N]` | `<plugin>/agent-jobs/agent-job.sh install collect-backlog [--hour N]` |
| `dry-run` | `... -Action run -Job collect-backlog -DryRun` | `... run collect-backlog --dry-run` (candidates only; run in the background) |
| `status` | `... -Action status` | `... status` |
| `pause` / `resume` | `... -Action pause -Job collect-backlog` / `-Action resume -Job collect-backlog` | `... pause collect-backlog` / `... resume collect-backlog` |
| `uninstall` | `... -Action uninstall -Job collect-backlog` | `... uninstall collect-backlog` (state and branch stay) |

Before `install`, the profile (`## Dev cycle` in `AGENTS.md`) must name `backlog`.

<!-- job -->

## Job: collect deferred and undone work into the backlog

Collect work whose intent is explicit: deferred, postponed, not done, left for a follow-up,
a later iteration, a next version or the future; a dropped task with "later"; a proposed
backlog row from a job report. Do not collect: out-of-scope statements without an intent to
do it later, open owner questions, wishes without an owner, defects (they belong to
`collect-issues`).

### Branch and state

- Branch `collect/backlog` unless the notes name another. If it exists and is not merged
  into `wip_branch`, continue it (worktree on the existing branch). If it is merged, delete
  it with `git branch -d` and create it again from `wip_branch`.
- `<state>/cursor` holds the `wip_branch` commit and the time of the last completed scan.
  `<state>/seen.md` is a table `| source | note | verdict | item |` of every note already
  judged; skip a note whose source and text are unchanged there.

### Sources

Without a cursor, scan everything once (the scan may span runs: `seen.md` keeps progress;
write the cursor only when the whole scan is complete). With a cursor, scan only:

- files changed in `git diff --name-only <cursor>..<wip_branch>`;
- reports of all jobs (header: state directories) newer than the cursor time, especially
  `autobacklog`'s proposed backlog rows and «what is left» sections.

Where intent hides: task sequences (dropped or deferred tasks, open proof points left for
later), task files («Out of scope» with "later", follow-ups), workflows (deferred decisions
with a chosen direction, "phase 2", "v2"), evidence (follow-ups), release notes (not
included in this release), closed bundles under `_completed/`, guides. Markers: deferred,
postponed, later, follow-up, future, next iteration, not done, TODO, v2 and their
equivalents in the documents' language (e.g. «отложено», «позже», «в следующей итерации»,
«не сделано», «будет», «в будущем»).

### Judge each candidate

- Not already tracked: compare with the `backlog` file on `wip_branch`, in the operator's
  working tree and on the collector branch, open bundles under `tasks_root`, and the
  `autobacklog` ledger.
- Current: apply the freshness check of `../autobacklog/SKILL.md`. Done later → `done`.
  Concept replaced → `outdated`. Only an owner decision without a chosen direction →
  `needs-owner` (record, do not add).
- Record every judged note in `seen.md` with its verdict.

### Add

- Add at most 10 rows per run, the most valuable first. Follow the backlog's own format and
  language. Existing bundle with open deferred work → update or add the row of that bundle.
  Work without a bundle → a row in a section for deferred work (create it once, in the
  document's language, e.g. «Отложенные и будущие задачи»): short intent, source link, date
  found, the next step («plan through the cycle»). Never create bundles here: that is
  `autobacklog`'s job.
- Each row links its source note and states why it is still current.
- Remove from the collector branch any row it added earlier that `autobacklog` has since
  finished (`done` in its ledger).

### Steps

1. Read the cursor, `seen.md`, the ledgers of all jobs and the `backlog` file (operator's
   working tree, `wip_branch` and collector branch). Record the `wip_branch` commit.
2. Scan the sources; judge every candidate.
3. DRY RUN: stop here; the report lists the candidates with verdicts and the rows you would
   add; no branch, no edits outside the state directory (`seen.md` stays unchanged).
4. Worktree on the collector branch; edit the `backlog` file; finish the change (common
   rules; documents only: check links and `git diff --check`).
5. Update `seen.md` and, when the scan is complete, the cursor.
6. Report: added rows with sources and freshness evidence, rejected candidates grouped by
   verdict. Ledger: one row per run, slug `collect`, the added rows' short names in the
   item column; `no-candidate` when nothing new was found.
