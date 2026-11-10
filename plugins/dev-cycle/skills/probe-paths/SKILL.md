---
name: probe-paths
description: >-
  Probe a running product for broken user paths: one iteration walks a few not-yet-covered
  scenarios as different roles across every surface (web UI, API, CLI, TUI, local daemon,
  MCP server), runs subagents on concurrent-use edge cases, and records dead ends, missing
  reverse actions, UI/API permission mismatches, races and states with no way out. State
  lives in files, so iterations can repeat on a timer without overflowing context. Finds and
  records only; fixes nothing. Use when asked to hunt UX gaps, dead-end branches or
  role/permission holes on a live stand («пройди пользовательские сценарии», «найди тупиковые
  ветки», «проверь роли и права вживую», «ux-проба», "probe user paths", "find dead ends").
argument-hint: "[focus area or scenario family] [--once]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Probe user paths

One call is one iteration: read the state files, pick uncovered scenarios, walk them live,
record findings, update the state. To repeat on a timer, wrap the call in the harness loop
(Claude Code: `/loop 15m /dev-cycle:probe-paths`); the loop ends with the session. Every
iteration starts from the files, never from chat memory.

You are the orchestrator. Subagents do the walking; you choose scenarios, write briefs and
record results. You find and record. You do not fix, commit, or edit product code and docs.

## Inputs

- Profile (`## Dev cycle`, see `task-layout`): `stand`, `boundaries`, `known_issues`,
  `jobs_state`, `probe_notes`.
- Probe notes (`probe_notes`, layout in
  [`references/probe-notes-template.md`](references/probe-notes-template.md)): surfaces and
  how to reach them, roles, how to create test tenants and accounts, the object prefix,
  hard limits, what the owner allows. No notes file → build it in iteration 1 from the
  repository (routes, permission catalog, CLI usage, compose files) and ask the owner only
  for what the repository cannot answer: which stand, and what must never be touched.
- State directory `<jobs_state>/probe-paths/`, never committed (formats in
  [`references/state-files.md`](references/state-files.md)): `STATE.md` (read first, under
  80 lines), `coverage.md`, `findings.md`, `scenarios-backlog.md`, helper scripts, test
  credentials.

## Hard limits

- Only the stand the notes name. Never production, never a real user's credentials, home
  directory, agent configuration or installed background services.
- Create your own tenants, accounts and objects with the notes' prefix and change only
  those. Reading shared data of the stand is allowed when the notes say so.
- No fixes, no commits, no edits outside the state directory. Do not edit the
  `known_issues` file: `collect-issues` or the owner promotes findings.
- No secrets in `findings.md` or reports. Test passwords live in one file of the state
  directory.
- A destructive check (lock-out, deletion, irreversible switch) runs only on an object
  created for it. Leave the broken sample in place as evidence and name it in `STATE.md`.

## What counts as a finding

| Type | Meaning |
| --- | --- |
| dead end | the user reaches a state or message with no next step |
| missing function | an action the user may expect does not exist (delete, undo, rename, transfer) |
| broken path | the step exists and fails, lies, or reports success for work not done |
| permission mismatch | UI, API, CLI or MCP disagree on what the role may do or see |
| race | concurrent actors produce duplicates, lost updates, dangling references or 5xx |
| footprint | the product leaves, grows or changes local state it does not account for |

Each finding carries a status: `confirmed` (reproduced live by you or a second run),
`reported` (one subagent run), `candidate` (seen, not reproduced), `by-code` (read from
source, not run), `stand-artifact` (caused by how the stand was prepared), `withdrawn`.
Say the status when you report; never present `reported` as `confirmed`.

## Scenario space

Pick from [`references/scenario-catalog.md`](references/scenario-catalog.md). Its families:
single-role paths per surface; lifecycle symmetry (every create has an undo, every state an
exit); permission matrix UI versus API; concurrent actors per surface pair; identity across
tenants (one person, several tenants, different roles, managed in one and owner in
another); many simultaneous users in one tenant with invariant checks; source-control
provider changes and failures (GitHub, GitLab); local footprint measurements; recovery from
corrupt or missing local state; account and tenant lifecycle; session and navigation edges.

Each iteration must differ from the previous one in role, surface pair and family.

## Iteration

1. Read `STATE.md` and the tail of `coverage.md`. Check that the stand answers; start it
   with the profile's `stand` command if the notes allow; never remove its volumes.
2. Choose 2–4 uncovered scenarios: different roles, at least one concurrent or
   cross-surface, at least one from a family not touched in the last three iterations.
3. Launch 1–2 subagents with self-contained briefs
   ([`references/subagent-brief.md`](references/subagent-brief.md)). One focus per
   subagent. A shared exclusive resource (the browser, a single CLI profile, a port) goes
   to one subagent whole; do not use it yourself while it runs.
4. While they run, touch nothing they depend on. Do at most one small live check yourself;
   your context is the scarce resource.
5. Record each returned report: de-duplicate against `findings.md` and the `known_issues`
   file (mark «already KI-NN» instead of adding), assign the next `F-NN`, set type,
   severity and status, update `coverage.md`, move unreached scenarios to
   `scenarios-backlog.md`.
6. Every third iteration, spend one subagent on confirmation: re-run the open `high`
   findings and the oldest `reported` ones independently, then set `confirmed`,
   `stand-artifact` or `withdrawn`.
7. Rewrite `STATE.md`: iteration count, finding count and next ID, objects created,
   blockers, the next scenarios. Fold old detail.
8. End with one line: iteration N, scenarios walked, new findings, total. Then list new
   findings by severity, and separately what was not reached and what needs the owner.

## Orchestrator rules

- A brief is the subagent's whole world: stand, accounts, object IDs, limits, what is
  already known, exact output format, cleanup duties, time budget.
- Subagents run out of time on wide briefs. Three focused tasks beat seven listed ones. A
  scenario missed twice goes into its own single-task brief.
- Name the shared objects no subagent may change, and give each one its own disposable
  objects. Two probes must not interfere; when they do, record the interference in the
  affected finding.
- A blocked path is a finding when a real user would be blocked the same way, and a
  `stand-artifact` when the stand caused it. Record blockers in `STATE.md` and take a
  scenario on another surface; do not loop on a blocker.
- A surface that cannot be driven (a TUI without a terminal) is audited from source and
  marked `by-code`.
- Your own mistakes on the stand go into the report (a role you demoted, an object you
  touched while a subagent used it).

## Stopping

Propose stopping when two iterations in a row bring fewer than three new findings, or
when only owner-blocked scenarios remain. On stop, write the final state and tell the
owner: where the files are, the counts by severity and status, which findings are
unconfirmed, what test data stays on the stand.

## Report language

`findings.md`, `coverage.md` and the chat report use the language of the project's
`known_issues` file (or the user's language when there is none). Routes, commands, flags,
status codes and error texts verbatim.
