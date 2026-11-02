---
name: autodebug
description: >-
  Scheduled unattended agent that fixes one item of the project's known-issues file per run
  on its own branch, then writes a report; never merges. Install, dry-run, pause, resume,
  check or remove the scheduler job (Windows Task Scheduler, cron on Linux and macOS) for the current repository. Use when asked
  to set up or manage automatic known-issue fixing («автофикс known issues», «поставь
  autodebug», "schedule autodebug").
argument-hint: "install [-Minute N | --minute N] | dry-run | status | pause | resume | uninstall"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Autodebug

Every 30 minutes a headless Claude Code agent picks one known issue it can fix without the
owner, fixes it in a worktree on its own branch, and writes a report and a ledger row. The
owner reviews the reports and merges the branches. Rules shared with `autobacklog`:
[`../../agent-jobs/common.md`](../../agent-jobs/common.md).

## Operator

Run from the target repository root; `<plugin>` is this plugin's root (two levels above
this file). The job runs Claude Code. Windows uses `agent-job.ps1` (PowerShell 7, Task
Scheduler); Linux and macOS use `agent-job.sh` (bash, cron) with `--minute N`, `--hour N`,
`--dry-run` instead of `-Minute N`, `-Hour N`, `-DryRun`.

| Argument | Windows | Linux, macOS |
| --- | --- | --- |
| `install` | `pwsh -NoProfile -File <plugin>/agent-jobs/agent-job.ps1 -Action install -Job autodebug [-Minute N]` | `<plugin>/agent-jobs/agent-job.sh install autodebug [--minute N]` |
| `dry-run` | `... -Action run -Job autodebug -DryRun` | `... run autodebug --dry-run` (selection only, 10–30 min; run in the background) |
| `status` | `... -Action status` | `... status` |
| `pause` / `resume` | `... -Action pause -Job autodebug` / `-Action resume -Job autodebug` | `... pause autodebug` / `... resume autodebug` |
| `uninstall` | `... -Action uninstall -Job autodebug` | `... uninstall autodebug` (state and branches stay) |

Before `install`, check the profile (`## Dev cycle` in `AGENTS.md`): `known_issues` must
name the file; `format`, `lint`, `test` must exist. Offer `jobs_state` and `job_notes`
(see `task-layout`) when the project has live environments or items the job must skip.
After `install`, suggest a `dry-run` and read its report with the user.

<!-- job -->

## Job: fix one known issue

### Source

1. The `known_issues` file of the profile, read from `wip_branch`
   (`git show <wip_branch>:<path>`), plus the items that only exist on the unmerged
   `collect-issues` branch (`collect/known-issues` unless the notes name another). Follow
   the file's own rules for item IDs, recheck lines and closing.
2. Only if no item is eligible: recent results on `wip_branch`, e.g. evidence and release
   notes changed in the last 14 days
   (`git log <wip_branch> --since=14.days --name-only --format= -- "<tasks_root>**/evidence/*.md"`).
   Look for defects marked FAIL, follow-up, «Remaining risks». A defect you fix from there
   goes into the report; one you do not fix goes into the report's Found section.

Re-verify in current code that the defect still exists before fixing it.

### Skip

- Items with any row in your ledger other than `dry-run`, and items that already have a
  branch of this job.
- Items with a row in the `autobacklog` ledger (header: state directories).
- Items the notes file excludes.
- Investigation items whose cause you cannot isolate in about 45 minutes: narrow the item
  with what you found (status `partial`) instead of guessing a fix.

Eligible when no `needs-owner` decision is needed, the fix and its regression test fit one
component, and it can be verified on this machine.

### Steps

1. Read both ledgers and this job's branches; list candidates, pick one, note 2–4 rejected
   ones with reasons. Record the `wip_branch` commit.
2. DRY RUN: stop here; ledger row `dry-run` for the pick.
3. Worktree and branch: `fix/<ID>-<short-slug>` unless the notes name another pattern.
4. Confirm the defect; write the failing test first where practical; fix the root cause.
5. Finish the change (common rules). In the branch, update the `known_issues` file: remove
   the item when fully fixed per the file's rule, otherwise narrow it. An item that exists
   only on the collector branch is not in your base: leave the file alone and say in the
   report that the item is fixed (the collector drops it). Update other docs only if
   behaviour changed.
6. Report and ledger row: `<slug>` is the item ID. Status `done` or `partial` (part fixed
   and the item narrowed; commit allowed).
