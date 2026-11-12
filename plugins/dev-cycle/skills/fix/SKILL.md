---
name: fix
description: >-
  Fix a bug from a report: a sentence, a screenshot, an error text, a log or a failing test.
  Reproduce the defect, find the root cause, then take the shortest path the cause allows: a
  direct fix with a regression test, a briefed developer with an independent check, or a
  planned change through cycle. The path moves up when the fix grows and down when the cause
  proves small. Use when the user reports broken behaviour, or asks to fix a defect or to
  find its cause ("bug", "doesn't work", "broken", "fails with", "fix this error", «баг»,
  «не работает», «сломалось», «ошибка при», «падает», «почини», «исправь баг», «найди
  причину»). Not for a failing check met inside a task that is being executed or validated:
  that task's skill handles it.
argument-hint: "<bug report: text, screenshot, log or failing test> [--diagnose] [--auto]"
metadata:
  contract: ../task-layout/SKILL.md
---

# Fix a bug

Input: a bug report in any form: a sentence, a screenshot, an error text, a log, a failing
test, a `known_issues` item ID. Claude Code passes `$ARGUMENTS`; Codex the request text.

| Option | Effect |
| --- | --- |
| `--diagnose` | stop after phase 4: report the cause and the path, fix nothing. A temporary test or temporary logging is allowed during the search and removed before the report; also "find the cause", «найди причину», «не чини» in the request |
| `--auto` | ask nothing, see [Autopilot](#autopilot); also "autopilot", «автопилот», «без вопросов» |

Output: the defect fixed, with a check that fails without the fix; or a statement of what
blocks the fix and what evidence would unblock it.

Two things are sized separately, and neither from the wording of the report:

- **How deep the search for the cause goes** (phase 3). It grows only while the cause is not
  found.
- **How heavy the fix process is** (phase 4). It follows from the cause and the fix outline.
  "Failed to delete role" can be a wrong ID in one line or a missing cascade in the schema.
  A long search can end in a one-line fix, and that fix still takes the direct path.

A caller's rule wins over this file. When a brief, a scheduled job or another skill sets
the tree or the branch, or bans a step (a merge, a commit, a question), work as the caller
says, skip the banned step and name it in the report.

Terms: a **component** is a part that is built or deployed on its own (a frontend app, a
service, a package). A **layer** is a tier inside a component (UI, API handler, service,
persistence, schema).

Language: status lines, questions and the report in the user's language. Briefs, tables and
commands in compact English. Identifiers, paths, commands and error text verbatim.

## Context

1. Root `AGENTS.md` and its `## Dev cycle` profile
   ([`task-layout`](../task-layout/SKILL.md#project-profile)): `format`, `lint`, `test`,
   `stand`, `known_issues`, branches, worktrees.
2. Nearest local `AGENTS.md` for every file you edit.
3. [`coding-rules`](../coding-rules/SKILL.md) for every edit, unless the project overrides
   them.
4. [Delegation](../task-layout/references/roles-and-models.md): read it only when a step
   below sends work to a subagent. The direct path does not need it.

## Phase 1. Intake

Write the defect statement. Everything later works from it, not from the chat.

```text
ACTION    what was done, and where: screen, URL, command, API call
EXPECTED  what should have happened
OBSERVED  what happened; the error text verbatim
WHERE     environment, version or commit; the account or data when it matters
SINCE     when it last worked, if known
```

- A screenshot: read it. Copy the visible error text exactly; name the screen and the
  control that was used. A subagent does not see the image, so the statement carries
  everything, plus the image path when the image is a file.
- Fill the gaps from the project before you ask. Search the code for the error text to find
  the code that shows it. Read `git log` for that area: a recent change is the first suspect.
- Check the profile's `known_issues` file. An existing item: use its ID and what it already
  established.
- Several defects in one report: one statement each. Fix them one at a time; defects with a
  shared cause are fixed once.
- Not a defect (the behaviour is as designed, or the feature does not exist): say so with
  the evidence and offer [`cycle`](../cycle/SKILL.md) for the change. Stop.

## Phase 2. Reproduce

Take the cheapest way that shows the defect, in this order:

1. an existing test that covers the action;
2. a new failing test at the layer where the defect shows;
3. a command or an API call;
4. the profile's `stand` with the host's browser tools, when both exist.

- Get the error behind the message: the response status and body, the server log line, the
  stack trace. The text on the screen is the symptom.
- Reproduce on a test, a stand or local data. Do not repeat a destructive or outward action
  (delete, payment, send) where the data is real: read the logs and responses there instead.
- Keep the reproduction. It is the final check, and the regression test when it is a test.
- No way to run it here, but the code shows the failure with certainty (the condition, the
  input from the report, the error it produces): the defect counts as shown. Continue, and
  say in the report that it was not reproduced by a run.
- Neither reproduced nor shown by the code: stop. Report what you ran and what you saw, and ask for one
  specific thing: the response body of the failing request, the log line at that time, the
  ID of the record. Do not fix a cause you have not seen fail.

## Phase 3. Locate the cause

Trace from the observed error to the line that produces it, then back to the first wrong
value or decision. The cause statement: `file:line`, the condition, why it gives OBSERVED,
and the commit that introduced it when the history shows one. A cause is shown by evidence
(a run, a log line, the code path with the report's input), not judged likely.

Deepen the search one step at a time. Stop at the first step that gives the cause.

1. **Direct trace.** You, with a handful of searches and reads. Most bugs end here.
2. **Hypotheses.** At most three, ranked by evidence, each with the check that would reject
   it. Run the checks; send the read-only ones in one message.
3. **Wider search.** When every hypothesis of step 2 is rejected, or when the trace crosses
   more than two components: `git bisect` when a working commit is known; temporary logging at the
   component boundaries; one researcher per component, in parallel
   ([delegation](../task-layout/references/roles-and-models.md)). Remove the temporary
   logging before the commit.
4. **Second opinion.** The advisor, when the host has one. A cause that crosses components
   and is still disputed: check the three conditions of
   [`consilium`](../consilium/SKILL.md).

Still not isolated: remove the temporary logging and stop. Report the narrowed area, the rejected hypotheses and the evidence
that would decide, and record the item ([left open](#a-bug-left-open)). Do not guess a fix.

Before you leave this phase, search for the same defect in sibling paths: the other callers
of the faulty function, and the other entities built from the same pattern (a broken role
deletion: check the deletion of users and groups). The fix goes where all callers pass.
Siblings you do not fix go into the report.

## Phase 4. Choose the path

Choose from the cause and the fix outline. Take the highest path that any signal names.

| Path | Signals | Process |
| --- | --- | --- |
| **direct** | one cause in one component; the fix and its test stay within five files (`coding-rules` cs-011), one layer, one verification run | you fix it: no documents, no subagents |
| **briefed** | more than one layer with separate verification; or more than five files; or the fix changes an authorization check, a schema or migration, or code that deletes or rewrites stored data. Still one [unit of work](../task-layout/references/roles-and-models.md#unit-size) | a developer in a worktree, then an independent check |
| **planned** | more than one unit of work; or a contract changes and its consumers must follow; or stored data needs repair; or the correct behaviour was never specified and needs a design | [`cycle`](../cycle/SKILL.md) |

Say the path and its signal in one line. When the user names a path, take it; when the
signals name a higher one, say so once. A named path also switches off the moves that
change the path: the [Moves](#moves) rows "to briefed", "to planned" and "to direct". The
rows that send you back to phase 3 still apply.

A question only the owner can answer (which of two behaviours is the correct one): ask it
before the first edit (a gate).

`--diagnose` ends here: report the statement, the cause, the path and the fix outline, and
record the item ([left open](#a-bug-left-open)).

## Direct path

1. Do it yourself, in the current tree and on the current branch. A subagent would read the
   project again and cost more than the fix.
   - `AGENTS.md` or `CLAUDE.md` forbids commits on this branch: create `fix/<slug>` from it
     first. Do not merge it back: name the branch and the merge command in the report.
   - The files the fix must touch hold uncommitted edits that are not yours: do not touch
     them. Work in a worktree as the briefed path sets it up.
2. Failing test first, where that layer has tests. A layer without tests: the reproduction
   is the check; do not build a test setup for one fix.
3. Fix the cause with a minimal diff. Do not catch, hide or reword the error where it shows.
4. [Close](#close).

## Briefed path

You coordinate and do not edit code: read
[delegation](../task-layout/references/roles-and-models.md) now.

1. Worktree `<worktree_root>/fix-<slug>`, branch `fix/<slug>` from the current branch; run
   `worktree_setup` when the profile has it.
2. The fix plan lives in the brief, not in a task file. Use the brief format of the
   delegation reference with all its lines. They carry the plan: the defect statement, the
   reproduction, the cause with its evidence, the fix outline by layer, three to six
   numbered checks (the reproduction passes; a regression test at the layer of the cause;
   each sibling path; one failure path), and what is out of scope.
3. Developer: strong tier, `high` (the roles table, debugging). The brief tells it to
   confirm the cause in the code before the first edit, to write the failing test first, and
   to do steps 2–5 of [Close](#close) in the worktree before it returns.
4. Independent check: a new QA developer agent (everyday tier, `high`; strong tier when the
   fix touches authorization or stored data). It gets the defect statement, the numbered
   checks and the branch, and not the developer's report. It reruns the reproduction and
   returns a verdict with proof for each check.
5. A failed check: return the failures to the developer once, stepped up as
   [tiers and effort](../task-layout/references/roles-and-models.md#tiers-and-effort) says.
   A second failure: see [Moves](#moves).
6. All checks pass: merge `fix/<slug>` into the branch you started from with
   `git merge --no-ff` (a gate: show the commits and ask), remove the worktree, and add the
   model notes rows.

A host without subagents: do steps 2–4 yourself in the worktree, in order, and say in the
report that the check was not independent.

## Planned path

1. Tell the user which signals make this a planned change (a gate).
2. A stopgap that removes the harm without hiding the defect (a guard, a correct error
   message, a disabled control): offer it as a direct fix first.
3. Record the item ([left open](#a-bug-left-open)).
4. Read [`cycle`](../cycle/SKILL.md) and follow it. The intent carries the defect statement,
   the cause, the evidence paths, the behaviour the fix must keep, and the `known_issues`
   item ID with the instruction to remove the item in the task that fixes the defect. The reproduction
   becomes an acceptance criterion of the first task. From here `cycle` owns the work and
   its gates apply.

## Moves

Compare the work with the phase 4 signals again at four points: when the cause is stated,
before the first edit, after each failed check, and when a worker reports.

| On path | Event | Move |
| --- | --- | --- |
| direct | the diff reaches a briefed signal: a sixth file, a second layer, a schema, an authorization check | to briefed. Create the worktree, move your own uncommitted edits of this fix into it (a patch from `git diff -- <your paths>`, plus the files you created), restore those paths here, and put what you learned into the brief |
| direct | the reproduction still fails after two fix attempts | the cause is wrong or incomplete: back to phase 3, one step deeper. No third variant without new evidence |
| briefed | the developer reports that the cause in the brief is wrong | back to phase 3, one step deeper, with the developer's evidence |
| briefed | the developer returns `partial` or a contract change whose consumers are outside the brief; or the independent check fails a second time | to planned. The `fix/<slug>` branch goes into the intent as earlier work |
| briefed | while you write the brief, the fix outline comes to one change in one component | to direct |
| any | a worker returns `needs consilium`, or the choice between fixes spans several domains | the three conditions of [`consilium`](../consilium/SKILL.md) hold: convene it. They do not: the cheaper steps of [hard questions](../task-layout/references/roles-and-models.md#hard-questions); what stays open is a question for the user |

Severity sets the urgency, not the path: a crash with a one-line cause is a direct fix.

## Close

For every path that changed code. On the direct path you do all of it; on the briefed path
the independent check does step 1 and the developer steps 2–5.

1. Rerun the original reproduction: the same action as in the report, in the same safe
   place as in phase 2. A new test that passes is not enough on its own. A defect that was
   shown by the code and never by a run: the regression test is the check.
2. Run the profile's `format`, `lint` and `test`; `{path}` is the directory of each touched
   package. A command the profile does not have: ask once, as the profile rules say; on
   autopilot take the command that the project's own files show (package scripts, CI
   configuration) and name it in the report.
3. `known_issues`: remove the item when the defect is fully fixed, or narrow it, as the
   file's own rules say.
4. Update other docs only where documented behaviour changed.
5. Commit per [git hygiene](../task-layout/SKILL.md#git-hygiene). The message names the
   symptom, the cause and the fix. Running this skill is the user's request for that
   commit: do not end with the fix uncommitted, unless a caller bans the commit.
6. When subagents ran: add the rows to the
   [model notes](../task-layout/references/roles-and-models.md#model-notes).

### A bug left open

`--diagnose`, a defect that was neither reproduced nor shown by the code, a cause that was
not isolated, a planned change that is not
finished: add or update the item in the profile's `known_issues` file by the file's own
rules, with the defect statement, what is established and what evidence would decide, and
commit that file. A profile without `known_issues`: the report carries it.

## Autopilot

`--auto`: nobody answers. Never ask: decide, record the decision in the report, continue.
The never-on-autopilot list of [`cycle`](../cycle/SKILL.md#autopilot) holds here too.

| Where the skill would ask | Autopilot decision |
| --- | --- |
| a fact is missing from the report | the reading most consistent with the code and the history; state the assumption |
| not reproduced, or the cause not isolated | record the item as left open; end the run with the report |
| which behaviour is correct (an owner decision) | the smallest reversible fix that keeps existing contracts and data |
| merge of `fix/<slug>` | proceed |
| the move to the planned path | proceed: follow `cycle` with `--auto` |
| a stopgap before the planned change | make it when it fits the direct path; otherwise skip it and name it in the report |

## Report

1. The outcome: fixed, partly fixed or left open, and what you need from the reader.
2. Symptom, cause (`file:line`, the condition), fix: one line each.
3. The path taken, its signal, and each move with its reason.
4. The reproduction and the verification commands with their results; verbatim on failure.
5. Sibling paths: fixed, or listed as open.
6. What was not checked, and whether the defect was reproduced by a run.
7. Branch, commits, worktree path; role, model and effort of each subagent.

Write it per [Reports](../task-layout/SKILL.md#reports).

## Anti-patterns

Fixing the symptom where it shows. Choosing the path from the wording of the report. A third
fix variant without new evidence. A task file or a bundle for a one-line cause. A fix across
several layers made in passing in the main tree. Claiming "fixed" without rerunning the
reproduction.
