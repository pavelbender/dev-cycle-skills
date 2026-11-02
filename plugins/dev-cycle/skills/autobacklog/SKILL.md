---
name: autobacklog
description: >-
  Scheduled unattended agent that advances one backlog item per run: checks that the item is
  still current, then implements, validates or reconciles it on its own branch, running new
  features through the dev cycle across several runs; never merges. Install, dry-run, pause,
  resume, check or remove the Windows Task Scheduler job for the current repository. Use when
  asked to set up or manage automatic backlog work («автобэклог», «поставь autobacklog»,
  "schedule autobacklog").
argument-hint: "install [-Minute N] | dry-run | status | pause | resume | uninstall"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Autobacklog

Every 30 minutes a headless Claude Code agent picks one backlog item that needs no owner
decision, proves it is still current, and advances it in a worktree on its own branch:
a task with tests, a proof or validation, a document reconciliation, or a new feature
through `cycle`. Unfinished bundles continue in later runs. The owner reviews the reports
and merges the branches. Rules shared with `autodebug`:
[`../../agent-jobs/common.md`](../../agent-jobs/common.md).

## Operator

Run from the target repository root; `<plugin>` is this plugin's root (two levels above
this file). Windows only; the job runs Claude Code.

| Argument | Command |
| --- | --- |
| `install` | `pwsh -NoProfile -File <plugin>/agent-jobs/agent-job.ps1 -Action install -Job autobacklog [-Minute N]` |
| `dry-run` | `... -Action run -Job autobacklog -DryRun` (selection only, 10–30 min; run in the background) |
| `status` | `... -Action status` |
| `pause` / `resume` | `... -Action pause -Job autobacklog` / `-Action resume -Job autobacklog` |
| `uninstall` | `... -Action uninstall -Job autobacklog` (state and branches stay) |

Before `install`, check the profile (`## Dev cycle` in `AGENTS.md`): `format`, `lint`,
`test` must exist; `backlog` names the routing index if the project keeps one (otherwise
the job scans bundles under `tasks_root`). Offer `jobs_state` and `job_notes` (see
`task-layout`) when the project has live environments, stands or items the job must skip.
After `install`, suggest a `dry-run` and read its report with the user.

<!-- job -->

## Job: advance one backlog item

Never spend a run on work that is out of date. Proving that a candidate is outdated and
recording it is a valid outcome.

### Sources

1. The profile's `backlog` file in the operator's working tree (read only): it may be ahead
   of `wip_branch` with uncommitted edits. Compare with `git show <wip_branch>:<path>` and
   trust the newer status of each row. Add the rows that only exist on the unmerged
   `collect-backlog` branch (`collect/backlog` unless the notes name another). No `backlog`
   key: open bundles under `tasks_root` (`02-task-sequence.md` outside `_completed/`).
2. Results of recent bundles on `wip_branch`: release notes and evidence changed in the last
   14 days. Look for open follow-ups, FAIL, `NOT_RUN`, «Remaining risks» that name work.
   Each candidate must point to a bundle or task file.
3. Defects belong to `autodebug`: skip items of the `known_issues` file and anything with a
   row in the `autodebug` ledger (header: state directories).

### State and continuation

- The latest ledger row per item counts. Skip items whose latest status is `done`,
  `partial` or `stalled`. Re-examine `abandoned` only if the reason no longer holds.
- `outdated`, `needs-owner` and `blocked` are skipped while fresh: re-examine one older than
  7 days or whose backlog row or job notes changed since the verdict.
- `already-done` marks a document reconciliation candidate, not a final state.
- Continue an item whose latest row is `in-progress` before any new item, if its next step
  is unblocked: create the worktree on its existing branch. After 6 runs on one item
  without `done`, set `stalled`.
- A bundle with several eligible tasks is one item: slug = bundle directory, branch
  `bl/<bundle>` unless the notes name another pattern. Each run does the next ready task in
  dependency order on that branch, so a task that depends on an unmerged earlier task
  builds on it. Status `in-progress` until no eligible task remains.

### Freshness check (every candidate you consider)

Verdicts: `actual` (still needed in the current product model), `already-done` (code is in
`wip_branch`, documents lag), `outdated` (concept, screen, endpoint or flow changed or was
replaced), `needs-owner` (per the decision policy), `blocked` (unreachable environment).

- Take the date of the row's status source; list later changes in its area:
  `git log <wip_branch> --since=<date> --oneline -- <bundle dir> <code paths it names>`.
- Grep closed bundles (`_completed/`), release notes, the `known_issues` file and the
  `01-workflow.md` of newer bundles for the feature's key terms together with supersession
  words: `replaces`, `superseded`, `instead of`, `dropped`, `removed`, `v1` and their
  equivalents in the documents' language.
- Confirm the entity, endpoint, page or command the task changes still exists in code and
  contracts. Renamed or removed → `outdated`.
- Check whether the described result already exists in code and tests (`already-done`).

Record every `outdated`, `already-done`, `needs-owner` and `blocked` verdict as a ledger
row without a branch (also in DRY RUN) so later runs skip the investigation; put the
evidence in the report.

### Eligibility and preference

Eligible: verdict `actual` or `already-done`; no `needs-owner` decision for the next step;
verifiable on this machine; done in this run, or advanced now and continued later.

A row that asks for acceptance, sign-off, a review, a manual walkthrough or a validation by a
human is not `needs-owner` by itself: do that work yourself to the extent this machine
allows, and mark only the cells that need what you cannot reach.

Validation and acceptance are allowed when backed by evidence: run `validate-task`, record
proofs with commands and output, set `_VAL` and `PASS` only for what you checked, mark each
cell you could not run `NOT_RUN` or `BLOCKED` with the reason. A package whose required
proofs all pass (or whose residual cells the owner already accepted in its documents) may
be closed per `tidy-folder`: move it to `_completed/`, update its status map, delete its
merged task branches with `git branch -d` (never `-D`).

Document reconciliation records only facts checked in code and tests.

Prefer: continuation > a task with code and tests > a proof or validation > a new feature
through the cycle > document reconciliation.

### New feature: unattended `cycle`

For a described package or intent without implementation, run the `cycle` skill with the
bundle path and `--no-stop`. Unattended overrides of its gates:

- Bundle path for a new intent: choose `<tasks_root>/<domain>/<slug>` from the existing
  domain layout yourself; record it in the report.
- Topic choice, a blocking owner question, a replan signal or failed validation: stop with
  `needs-owner` (or `blocked`) and the exact question; commit planning documents already
  produced.
- Branches: the profile's `bundle_branch` is this run's branch; task branches and worktrees
  from `run-bundle` follow the profile. Merge task branches only into the bundle branch,
  never into `wip_branch`: that gate is the owner's.
- Remove every worktree you created, task worktrees included. Status `in-progress` while
  stages remain, `done` when execution is complete on the bundle branch.

### Steps

1. Read both ledgers and the branches of both jobs; list candidates with verdicts; pick one;
   note rejected ones with reasons. Record the `wip_branch` commit.
2. DRY RUN: stop here; `dry-run` row for the pick plus the verdict rows.
3. Worktree and branch: `bl/<slug>`, the continued branch, or the bundle branch.
4. Read the task file and the code it touches; confirm the gap still exists.
5. Implement (or run the cycle, validation or proof) following the dev-cycle skills: status,
   suffixes, evidence.
6. Finish the change (common rules). Update the bundle's sequence and status map on the
   branch. Edit the `backlog` file on the branch only if the operator's working-tree copy
   equals `wip_branch`'s (`git diff --quiet -- <backlog>` in the main checkout); otherwise
   put the proposed row text in the report. Never remove a row of an unclosed package.
7. Report (add a section with the freshness verdicts and a section with the proposed backlog
   row when the backlog was not edited) and ledger rows. Extra statuses: `in-progress`,
   `stalled`, `outdated`, `already-done`.
