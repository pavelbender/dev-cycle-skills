---
name: collect-issues
description: >-
  Scheduled unattended agent that walks the repository's documents, job reports and code
  markers for notes about remaining problems, checks that each problem still exists, and
  adds the untracked ones to the project's known-issues file on a rolling branch that
  autodebug also reads. Install, dry-run, pause, resume, check or remove the scheduler job (Windows Task Scheduler,
  cron on Linux and macOS) for the current repository. Use when asked to set up or manage automatic
  known-issue collection («сборщик known issues», «поставь collect-issues»,
  "schedule collect-issues").
argument-hint: "install [-Hour N | --hour N] | dry-run | status | pause | resume | uninstall"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Collect issues

Every 6 hours (by default at 00:00, 06:00, 12:00, 18:00) a headless Claude Code agent reads
what changed since its last run, finds notes about problems that remain, verifies them in
code, and records the untracked ones in the `known_issues` file on the branch
`collect/known-issues`. `autodebug` reads that branch too, so a collected item can be fixed
before the owner merges it. Rules shared with the other jobs:
[`../../agent-jobs/common.md`](../../agent-jobs/common.md).

## Operator

Run from the target repository root; `<plugin>` is this plugin's root (two levels above
this file). The job runs Claude Code. Windows uses `agent-job.ps1` (PowerShell 7, Task
Scheduler); Linux and macOS use `agent-job.sh` (bash, cron) with `--minute N`, `--hour N`,
`--dry-run` instead of `-Minute N`, `-Hour N`, `-DryRun`.

| Argument | Windows | Linux, macOS |
| --- | --- | --- |
| `install` | `pwsh -NoProfile -File <plugin>/agent-jobs/agent-job.ps1 -Action install -Job collect-issues [-Hour N]` | `<plugin>/agent-jobs/agent-job.sh install collect-issues [--hour N]` |
| `dry-run` | `... -Action run -Job collect-issues -DryRun` | `... run collect-issues --dry-run` (candidates only; run in the background) |
| `status` | `... -Action status` | `... status` |
| `pause` / `resume` | `... -Action pause -Job collect-issues` / `-Action resume -Job collect-issues` | `... pause collect-issues` / `... resume collect-issues` |
| `uninstall` | `... -Action uninstall -Job collect-issues` | `... uninstall collect-issues` (state and branch stay) |

Before `install`, the profile (`## Dev cycle` in `AGENTS.md`) must name `known_issues`.

<!-- job -->

## Job: collect untracked problems into the known-issues file

A known issue is a defect, regression, broken or missing guarantee, unsafe behaviour or
operational risk that is real now and not yet tracked. Planned or deferred work is not a
known issue: leave it to `collect-backlog`.

### Branch and state

- Branch `collect/known-issues` unless the notes name another. If it exists and is not
  merged into `wip_branch`, continue it (worktree on the existing branch). If it is merged,
  delete it with `git branch -d` and create it again from `wip_branch`.
- `<state>/cursor` holds the `wip_branch` commit and the time of the last completed scan.
  `<state>/seen.md` is a table `| source | note | verdict | item |` of every note already
  judged; skip a note whose source and text are unchanged there.

### Sources

Without a cursor, scan everything once (the scan may span runs: `seen.md` keeps progress;
write the cursor only when the whole scan is complete). With a cursor, scan only:

- files changed in `git diff --name-only <cursor>..<wip_branch>`;
- reports of all jobs (header: state directories) newer than the cursor time, especially
  their «Found», «Risks and what is left» and blocked cells.

What to look for:

- evidence, validation reports and release notes: FAIL, `NOT_RUN` or `BLOCKED` cells caused
  by a defect, «Remaining risks», «Known issues / follow-ups», «not verified» with a reason
  that is a defect, and their equivalents in the documents' language;
- task files and workflows: drift, residual defects, workarounds with a known flaw;
- code: `TODO`, `FIXME`, `HACK`, `XXX`, `BUG` comments that describe a defect or risk (not
  a wish for a feature);
- items the notes file adds.

### Judge each candidate

- Not already tracked: compare with the `known_issues` file on `wip_branch` and on the
  collector branch, closed items in its history, and both ledgers of `autodebug`.
- Still real: read the current code on `wip_branch`; confirm the problem exists. Gone or
  fixed → verdict `fixed`. Replaced concept → `outdated` (the freshness check of
  `../autobacklog/SKILL.md` applies).
- A defect, not planned work → otherwise `not-an-issue` (hand planned work to
  `collect-backlog` by leaving it alone).
- Record every judged note in `seen.md` with its verdict.

### Add

- Add at most 10 new items per run, the most severe first. Follow the file's own format and
  rules: ID scheme (next free ID across `wip_branch`, the collector branch and the branches
  of `autodebug`; never reuse one), headings, recorded date, status line, sections for
  current state, problems and proposed direction, code pointers. Keep the file's language.
- Each item names its source note (path and line or report) and the evidence that it is
  still open. The proposed direction is one technical path when there is one; otherwise say
  the decision the owner must take.
- Remove from the collector branch any item it added earlier that `autodebug` has since
  fixed (`done` row in its ledger), so merging the branch never re-adds a fixed item.

### Steps

1. Read the cursor, `seen.md`, the ledgers of all jobs and the `known_issues` file
   (`wip_branch` and collector branch). Record the `wip_branch` commit.
2. Scan the sources; judge every candidate.
3. DRY RUN: stop here; the report lists the candidates with verdicts and the items you
   would add; no branch, no edits outside the state directory (`seen.md` stays unchanged).
4. Worktree on the collector branch; edit the `known_issues` file; finish the change
   (common rules; documents only, so `format`/`lint`/`test` are not needed unless the notes
   say otherwise; check links and `git diff --check`).
5. Update `seen.md` and, when the scan is complete, the cursor.
6. Report: added items with sources and evidence, rejected candidates grouped by verdict.
   Ledger: one row per run, slug `collect`, item IDs added in the item column, e.g.
   `| <stamp> | collect: KI-51, KI-52 | done | collect/known-issues | <commit> | reports/<file> |`;
   `no-candidate` when nothing new was found.
