# Delegation: roles, models, effort

Read by every skill that hands work to a subagent: `cycle`, `run-bundle`, `consilium`,
`plan-feature`, `write-task`, `execute-task`, `validate-task`. This file is the one place that
says when and how to delegate. A skill names only its own fan-out points and links here.

Contents:

- [When to delegate](#when-to-delegate)
- [Coordinator](#coordinator)
- [Layers](#layers)
- [Unit size](#unit-size)
- [Parallel work](#parallel-work)
- [Test runs](#test-runs)
- [Brief](#brief)
- [Roles](#roles)
- [Tiers and effort](#tiers-and-effort)
- [Claude Code models](#claude-code-models)
- [Hard questions](#hard-questions)
- [Model notes](#model-notes)

## When to delegate

A subagent starts with an empty context. It knows only your brief, and you see only its
report. It reads the project again and spends its own tokens, so every subagent adds to the
cost of the run, and several at once multiply it.

Delegate a unit of work when it is self-contained and at least one of these holds:

- it can run at the same time as other units: independent work areas, independent questions;
- it would fill your context with output you will not need again: searches, logs, test runs,
  large reads;
- it needs a view that is independent of yours: validation of finished work, a consilium
  position;
- your skill gives the stage to a role agent (see [Coordinator](#coordinator)).

Do the work yourself when it is a handful of tool calls, a lookup whose target you already
know, a single-file edit, a step that needs most of your current context, or a step that
needs frequent back-and-forth with what you just did.

## Coordinator

On a run with several stages or tasks (`cycle`, `run-bundle`, the briefed path of `fix`) you
coordinate: you brief role
agents, check what they return, merge and report. Workers edit code and task files; you do
not, except for a consilium record. Your context has to last the whole run, and a second writer in a tree breaks the
one-committer rule. A host without subagents runs the stages itself, one at a time; say so in
the report.

- A subagent does not ask the user. It returns its questions in the report. You ask the user,
  or decide on autopilot.
- A report is a claim, not a proof. Check the done criterion yourself before you record a
  unit as done: file state, `git status --short`, a rerun of the named check.
- A unit is not done while something it started is still running (a background command, a
  helper). Wait for it.
- Shared documents (`02-task-sequence.md` rows, README indexes) have one writer between
  waves: you. A worker does not edit them.
- A message without a tool call ends your turn, with or without autopilot. While work is
  open, every message carries the next tool call; a status note goes in the same message.
  Do not stop to report because a task or a wave finished.
- A notice that an agent "is waiting on its own background work" is not a return. Do not
  answer it, do not tell the user, do not start a monitor for it. Act on a return, a
  question or a failure.
- Relay a return as one verdict line, the counts, and the decisions it needs from the user.
  The criteria matrix and command output stay in `evidence/`.

## Layers

Count layers below the main conversation. The usual shape:

| Layer | Who | Typical work |
| --- | --- | --- |
| main | the coordinator, or a skill the user called directly | brief, check, merge, report |
| 1 | role agent | one whole skill: a task, a pass, a validation, a consilium position |
| 2 | helper | one `SNN` item, an evidence pack, a check per criterion, a lookup |
| 3 | leaf | a read-only lookup or a noisy command for a helper |

- A skill can run at any layer. `execute-task` is the main conversation when the user calls
  it and layer 1 under `run-bundle`. Reason in layers left, not in fixed numbers.
- Claude Code: three layers below the main conversation by default. The user can change the
  limit with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (for example `4`); a skill does not
  change it. At the limit the host removes the Agent tool. No Agent tool: do the work
  yourself and return one report. Codex: follow the depth the host allows, same rule.
- Go one layer deeper only when the [when-to-delegate](#when-to-delegate) test passes at
  that layer. Each layer costs tokens and loses detail at the hand-off, so most units end at
  layer 1 or 2.
- A subagent reports to its parent only. Questions for the user and requests for a consilium
  travel up in the reports. Only the main conversation asks the user or convenes a
  consilium.
- Every brief says how many layers are left: "helpers allowed, 2 layers left" or "no
  helpers".
- Claude Code runs at most 20 subagents at once in a session, counted over the whole tree
  (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`). Keep a wave to at most 5 role agents, each with
  at most 3 helpers running. On `Concurrent subagent limit reached` wait for a running
  subagent to finish; do not retry at once.

## Unit size

A unit is what one agent does in one context: a task for a developer, a pass for an
architect, an `SNN` item for a helper.

- Target: the worker finishes with its context at or below about 300–500 thousand tokens.
  Every request sends the whole context again, so a long context is paid for on each turn.
  For the light tier the target is about 100 thousand, because Haiku 5.5 costs more per
  token on longer prompts. This is a target, not a rule: a unit that cannot be split without
  cutting a contract in half stays whole.
- Nobody can count tokens before the work. Signs that a unit is too big: it changes more
  than one layer with separate verification; it changes more than five files
  (`coding-rules` cs-011); it needs more than one long verification loop (a stand, a
  migration and a UI check together). Split it at planning: more tasks in `plan-feature`,
  more `SNN` items in `write-task`.
- The limit comes from sizing units and handing off noisy work, not from a number in the
  brief. Do not write a token budget into a brief: a budget shown to the model changes how
  much it spends. General-purpose subagents have no hard cap. The two read-only agent types
  of the plugin have one: their context is compacted at 500 thousand tokens.
- A worker whose unit grows past its brief (many more files than the brief named, long
  repeated output) hands read-heavy and noisy parts to helpers when layers are left.
  Otherwise it commits what is finished and returns `partial` with the list of what is left.
  The parent briefs a fresh worker for the rest; nothing restarts from zero.

## Parallel work

- Send independent calls in one message so they run at the same time: Agent calls, file
  reads, searches.
- Read-only work runs in parallel freely within the concurrency limit: searches, reads,
  evidence packs, consilium positions, validations of different tasks.
- Order units by dependency. Units with no edge between them form a wave. The next wave
  starts when the previous one is checked and merged or committed.
- One committer per tree. Parallel writers are allowed in two cases:
  - **Separate worktrees.** Always safe; `run-bundle` runs tasks this way.
  - **One tree, disjoint files.** Helpers whose allowed-change sets are pairwise disjoint and
    whose check is scoped to their own paths and writes no shared state (no migrations,
    lockfiles, generated registries, shared database). They edit and run their own check.
    They do not stage, commit or run repository-wide format. The parent integrates, runs
    `format`, `lint` and the tests, and commits.
- Any doubt about overlap: run in sequence.

## Test runs

A test run costs wall-clock time, and every worker that repeats it pays again. Most of the
time lost in the measured runs was repeated full suites, not slow tests. These rules apply to
every skill that runs tests; a project's `boundaries` line may tighten them, never loosen.
They limit what runs, not what a worker may spend: they are not a token budget.

- **Inside a task: focused.** The commands the acceptance criteria name, plus the profile's
  `test` on the paths the change touches and on their direct consumers. Before editing
  behaviour that tests assert (an order, a label, a message), grep every test and document
  that asserts the old value, by every spelling of it, and update them in the same pass.
- **A full package or suite is not a task check.** It runs in a task only when a criterion
  names it, or the task changes shared code (router, store, shared UI, schema, migration,
  generated contract). Then it runs once, last, after `format` and `lint`.
- **One gate.** The coordinator runs the profile's full suites once on the merged head, after
  the last merge (or the last merge of the target branch into the bundle branch), not once
  per task. A failure outside a task's own tests: rerun that test alone once; a flake listed
  in the known issues is not a task failure; otherwise map it to the task whose work areas
  hold the code and brief that task's developer.
- **Record every run that backs a claim** in `evidence/TNN-<slug>-run.md` with the commit
  SHA, the command, the exit code and the runner's summary line (`passed … in N s`,
  `Test Files`/`Tests`/`Duration`). When you filter output, keep that line and the names of
  failing tests.
- **Do not repeat a green run.** A run an earlier agent recorded green on the same code is
  cited, not rerun. "Same code" means `git diff --quiet <sha> HEAD -- <code paths>` is clean:
  status and evidence commits change `HEAD`, not the code. The QA developer runs the task's
  tests and its own mutations, not the developer's full run. A mutation drill runs the one
  test that covers the mutated code, and the touched package once after the last revert.
- **A long run is one background command and one wait.** Start it as a background command and
  wait for its single completion notice. No polling loop, no monitor per run, no foreground
  command with `sleep`. A worker that waits on its own run does not return until the result
  is in. Where the host has no background commands, use a foreground timeout from the profile.
- **Shared state is one runner at a time.** One test runner on a shared database. Helpers do
  not start tests that use it. In a parallel wave workers run focused tests, type-check and
  lint; a full web suite runs only on a quiet machine, otherwise timeouts look like failures.
- **Estimate from measurement.** The wait for a gate comes from the last recorded duration in
  `evidence/`, not from memory. A package that took over two or three minutes in one run is
  slow: say so in the profile (`boundaries` or a note beside `test`) with its timeout flag.

## Brief

Write the brief for a capable colleague who has never seen this project: what to do, what it
is for, where to work, what done looks like. Give the reason with a constraint ("do not edit
`migrations/`: applied migrations are immutable"); a reason lets the worker handle a case the
rule did not name.

```text
ROLE     <role>; <model>, <effort>
GOAL     <one outcome, and what it is for>
READ     <skill file to follow, with its arguments> | <files and symbols to start from>
WORKDIR  <tree to work in>
SCOPE    <paths you may change | read-only>; out of scope: <…>
RULES    <the profile's boundaries line>; <owner decisions that apply>; do not push
HELPERS  <helpers allowed, N layers left | no helpers>
DONE     <checkable criterion: a command, a file state, a verdict line>
RETURN   <exact report shape>; questions for the user and `needs consilium` go here, do not ask
COMMIT   <your files, per Git hygiene, before you return | do not commit: the parent commits>
MODE     <the autopilot line, when on>
```

Add these lines where they apply:

- Every worker: "Keep working until everything in GOAL is done and checked. Stop to report
  only when you cannot go on without an answer, or before a risky step. When the work is
  done and checked, stop and report. Do not add features, files, refactors or review rounds
  that were not asked for, and do not start reviewer subagents; name useful extras at the
  end." Workers at `low` and `medium` effort need it most: they stop early more often.
- A worker that changes code: "Before you report done, run a real check that exercises the
  change: the task's tests, the type-check or the build. A check that failed to start does
  not count. If no real check can run here, say which one you did not run and why. Test runs
  follow the Test runs rules of the delegation reference: focused by default, no repeat of a
  green run on the same code, one background command per long run, the summary line in the
  evidence."
- A worker in a worktree: "No `git stash`: the stash is shared by every worktree. Write
  scratch files only in your own directory under the scratchpad. Stop a process only by a PID
  you started and recorded, never by port or by name. When a check fails and you investigate,
  read the unfiltered output. On a CRLF checkout change files with `Edit`, not with a
  scripted replace."

Keep out of a brief:

- Requests to write out reasoning or to "think step by step" in the reply. Ask for the
  result, the evidence (`file:line`, command and output) and the risks. Current Claude models
  can refuse a request to reproduce their reasoning, and it adds nothing to the evidence.
- Your own hypothesis stated as a fact. Write "check whether …" and name what you already
  ruled out.
- Token budgets and countdowns ([Unit size](#unit-size)).
- Long pasted material in the middle. Give paths, or put the long text first and the
  instruction and return format last.

Return shape: the result first, then the evidence, then open questions. `partial` when
unfinished, with the list of what is left. Ask for at most about 20 lines: the criteria
matrix and the command output go to the evidence file, the return links it.

## Roles

| Role | Does | Where in the cycle | Tier, start effort |
| --- | --- | --- | --- |
| system architect | target model, invariants, contracts between components | `plan-feature` workflow and sequence; replan; consilium | deep, `high` |
| solution architect | task design against code: contracts, changes by layer, slices | `write-task` draft, detail, slices; consilium | strong, `medium`; many layers or contracts → `high` |
| uiux expert | actors, flows, screen and command states, UI review | `plan-scenarios`; visual checks of UI tasks; consilium | strong, `medium` |
| developer | implements one task or one briefed bug fix | `execute-task`; `fix` | everyday, `medium`; long or loosely specified → `high`; cross-layer → strong, `medium`; debugging → strong, `high` |
| QA developer | test cases, independent validation, failure paths | `write-task` validation; `validate-task`; the independent check of `fix`; consilium | everyday, `high`; security or data paths → strong, `high` |
| slice helper | one `SNN` item: a patch, tests for a ready criterion, an evidence pack | inside `execute-task` | everyday, `medium`; mechanical → light, `medium` |
| researcher | read-only search in code and documents, evidence packs | evidence packs, drift checks, lookups | light: `low` for a short lookup, `medium` for an evidence pack; synthesis across sources → everyday, `medium` |
| release manager | merges, `tidy-folder`, evidence, final report | `run-bundle` phases 4–5; `tidy-folder`; consilium | light, `medium`; conflicts → everyday, `medium` |

The task's `signals:` field ([proportion](../SKILL.md#proportion)) picks the starting tier
inside a row: `[]` → the row's lower value (everyday developer, everyday QA at `high`);
a non-empty list or a missing field → the row's strong value, and QA is strong, `high`.
Model notes still override it.

A role agent runs a whole skill and decides what that skill decides. A slice helper makes no
architectural decisions (`write-task` principle 8). No role pushes, deploys or publishes
unless the project's rules and the task say so.

## Tiers and effort

Stay in the host's family: Claude Code spawns Claude models, Codex spawns Codex models. Use
the latest stable version of the family.

| Tier | Claude Code: Agent `model` | Codex: spawn `model` | Codex start effort | Strength, speed |
| --- | --- | --- | --- | --- |
| deep | `fable` | newest Astra | `low`–`medium`, hard `high` | hardest work, architecture, long autonomous runs; slowest |
| strong | `opus` | newest Sol | `medium`, hard `high` | complex code, refactoring, debugging; medium |
| everyday | `sonnet` | newest Terra | `low`–`medium` | everyday coding, tests, review, UI; fast |
| light | `haiku` | newest Luna | `low`, harder `medium`–`high` | small edits, docs, search, bulk work; fastest |

- The effort values in the roles table are Claude Code values; see
  [Claude Code models](#claude-code-models). Codex: take the role's tier and the effort from
  the Codex column, the hard value where the role row names a harder case.
- Codex: pass `model` and `model_reasoning_effort` on the spawn. Use the newest ID of the
  family the host shows, for example `gpt-6.1-sol`. Do not use an ID from memory. Unknown ID:
  omit `model`, so the spawn inherits it, and record `inherited`. A custom agent file that
  sets `model` wins over the spawn value; record the file's value as effective.
- The coordinator runs on the session's model, which the user chose. When a stage needs a
  deeper model than the session has, delegate that stage to the deep tier.
- Workers start at the table value and go no higher than `high`. `xhigh` only for the deep
  tier on architecture or consilium work where the notes show a gain. `max` is not used.
- Pick the role's tier and effort, then apply the notes. Take the lowest tier the notes show
  succeeding for this role and task kind.
- After a failed or rejected result, step up once: effort first, then tier. Do not retry the
  same model and effort on the same failure.

## Claude Code models

How the Agent call works:

- Agent type. Roles that write, and helpers that must run a command (git history, a test
  run), use the general-purpose type (`general-purpose`), unless the project defines a custom
  agent for the role. The plugin ships two read-only types whose tools cannot edit files or
  run commands: `dev-cycle:researcher` for the researcher role (reads and searches only;
  defaults `haiku`, `medium`) and `dev-cycle:consilium-member` for consilium seats. Use them
  where the work is reading: the limit is enforced by the host, not asked for in the brief.
  A `model` or `effort` on the call overrides the type's default. When the host does not
  list these types (Codex, or the skills installed without the plugin), use the
  general-purpose type with `SCOPE read-only` in the brief.
- Pass `model` (an alias: `fable`, `opus`, `sonnet`, `haiku`) and `effort` on every Agent
  call. A subagent on another model does not inherit the session's effort; without `effort`
  it runs at that model's default, which is `medium` for all four. The alias resolves to the
  newest version of the family. When the session's model belongs to the same family, the
  alias resolves to the session's exact model.
- The per-call `effort` parameter needs Claude Code 2.1.292 or later. When the Agent tool has
  no `effort` parameter, pass `model` only and record the effort as `default`.
- The user's environment can override both (`CLAUDE_CODE_EFFORT_LEVEL`,
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`). Record what the host reports as effective.
- Effort is calibrated per model: the same name is not the same depth on two models. Lower
  effort means fewer tool calls and less checking, not only less thinking. To get less
  thinking, lower the effort; an instruction to "answer directly" does not do it. Effort
  does not shorten a report; ask for the length in the brief.
- All four models have a 1M-token context window.

What each model needs from a brief:

| Alias, model | Effort | Behaviour to plan for |
| --- | --- | --- |
| `fable`, Fable 5.2 | `high` carries most of the gain. `xhigh` only for the hardest long design work. `low` is already strong on well-specified units. | Reads instructions literally: a "never" is absolute, so write the scope and the reason, and write "ask before X" when you mean ask. At `low` and `medium` it can end a turn early with a list of what is left; the "keep working" line prevents it. It delegates readily when a prompt invites it; the when-to-delegate test is the brake. It adds to existing structure and leaves duplication unless told it owns the code; dev-cycle workers keep minimal diffs, so do not tell it that it owns the code. |
| `opus`, Opus 5.5 | `medium` is the working level. `low` comes close on coding at much lower cost. `high` for many-layer design and debugging. | Reports progress often and can end a turn on a progress report with work still open: name the done criterion, and say that a status note is not a stop. It starts acting quickly: on a loosely specified question tell it to read the relevant sources first. |
| `sonnet`, Sonnet 5.5 | `medium` for a well-specified unit (a task file after its four passes is one). `high` for long or hard units and for validation. Not above `high`. | At `low` it can skip verification. At `low` and `medium` it can stop to check in before the work is done. It adds tests, docs and small files nobody asked for. At `xhigh` and `max` it starts its own review rounds and reviewer subagents. For the hardest long work use the strong tier, not more effort. |
| `haiku`, Haiku 5.5 | `medium` is the working level. `low` only for a short lookup with a short brief. `high` when a unit at `medium` missed a step of its instructions. Above `high` use `sonnet`. | In a long brief at `low` it skips searches, stops early and skips checks. Keep its unit near 100 thousand tokens of context. |

## Hard questions

Take the cheapest step that can settle the question:

1. **Evidence.** Read the code, run the check. Most questions end here.
2. **Advisor.** When the host gives you an advisor tool, one call settles a decision inside
   one domain or gives a second opinion on your approach. An agent without the tool skips
   this step.
3. **Consilium.** When the question spans several functional domains of the product, a wrong
   answer is costly to reverse, and the advisor's answer is missing, partial or disputed by
   the evidence: [`consilium`](../../consilium/SKILL.md). Only the main conversation convenes
   it. A subagent returns `needs consilium: <question> · <domains> · <evidence paths>`.

A decision that belongs to the owner stays with the owner. A consilium can prepare the
options; it does not replace the owner, the never-on-autopilot list of `cycle`, or
`needs-owner` in the unattended jobs.

## Model notes

Observed results beat vendor claims. The notes record what this project saw.

File: the profile's `model_notes`, default `.dev-cycle/model-notes.md` in the main
checkout. It is state, not work: do not commit it. When `git check-ignore -q` fails, add
`.dev-cycle/` to `.git/info/exclude`. If the host cannot write `.git`, add it to `.gitignore`
in a commit instead. Only the coordinator writes the file; workers report to it.

Read it before the first delegation of a run. Append one log row after each delegated unit
of layer 1; helpers are counted in their parent's row.

```markdown
# Model notes

<!-- Coordinator-written. Max 40 log rows; one summary row per host, model, role. -->

## Summary

| host | model, effort | role | task kind | verdict | n | since |
| --- | --- | --- | --- | --- | --- | --- |

## Log

| date | host | requested | effective | role | task kind | outcome | retries | minutes | note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
```

- `effective`: the model the host reports for the run, `inherited`, or `unknown`. Learn only
  from rows with a known effective model.
- `task kind`: short and reusable, for example `single-layer api`, `migration`, `ui form`,
  `doc pass`, `consilium`.
- `outcome`: `ok`, `ok-after-fix` (the check sent it back once), `partial`, `fail`,
  `escalated`.
- `minutes`: wall clock when known, else `-`.
- `note`: one observed fact, for example "missed the permission check", "invented an API".
  Write what happened, not a rule for the future: a note such as "do not use haiku here"
  outlives its reason.
- Over 40 log rows: fold the oldest into Summary (update `verdict`, `n`), then delete them.
- A Summary row with `n` ≥ 3 like-for-like observations overrides the start values above for
  that role and task kind. Below 3 it is a hint.
- Only observations go here, not vendor claims.

Each final report lists role, model and effort per delegated unit and the rows added.
