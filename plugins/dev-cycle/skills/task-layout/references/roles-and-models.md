# Roles, models and model notes

Read by every coordinator: `cycle`, `run-bundle`, and any skill that delegates to a subagent.

## Coordinator

On a multi-stage or multi-task run you coordinate. You brief subagents, check what they
return, merge and report. You do not edit code or task files yourself. A host without
subagents runs the stages itself, one at a time; say so in the report.

- One writer per tree at a time. Parallel writers only in separate worktrees.
- A subagent never asks the user. It returns its questions in the report; you ask the user,
  or decide them on autopilot.
- A writing subagent commits its own files per
  [Git hygiene](../SKILL.md#git-hygiene) before it returns. You check `git status --short`.
- Brief: role, goal, the skill to read and its arguments, exact files, forbidden actions,
  done criterion, return format, the profile's `boundaries` line.

## Roles

| Role | Does | Where in the cycle | Tier, start effort |
| --- | --- | --- | --- |
| system architect | target model, invariants, contracts between components | `plan-feature` workflow and sequence; replan | deep, `high` |
| solution architect | task design against code: contracts, changes by layer, slices | `write-task` draft, detail, slices | strong, `medium`; many layers → `high` |
| uiux expert | actors, flows, screen and command states, UI review | `plan-scenarios`; visual checks of UI tasks | strong, `medium` |
| developer | implements one task or slice | `execute-task` | everyday, `medium`; cross-layer or debugging → strong, `high` |
| QA developer | test cases, independent validation, failure paths | `write-task` validation; `validate-task` | everyday, `medium`; security or data paths → strong, `high` |
| researcher | read-only search, docs, logs, evidence packs | evidence packs, drift checks | light, `low`; synthesis → everyday |
| release manager | merges, `tidy-folder`, evidence, final report | `run-bundle` phases 4–5 | light, `low`; conflicts → everyday |

A role subagent runs a whole skill and decides what that skill decides. Rule 8 of
`write-task` (no architectural decisions) applies to slice helpers. No role pushes,
deploys or publishes unless the project's rules and the task say so.

## Tiers

Stay in the host's family: Claude Code spawns Claude models, Codex spawns Codex models. Use
the latest stable version of the family.

| Tier | Claude Code: Agent `model` | Codex: spawn `model` | Vendor start effort | Strength, speed |
| --- | --- | --- | --- | --- |
| deep | `fable` | newest Astra | Fable `high`, hard `xhigh`; Astra `low`–`medium`, hard `high` | hardest work, architecture, long autonomous runs; slowest |
| strong | `opus` | newest Sol | `medium`, hard `high` | complex code, refactoring, debugging; medium |
| everyday | `sonnet` | newest Terra | Sonnet `medium`, hard `high`; Terra `low`–`medium` | everyday coding, tests, review, UI; fast |
| light | `haiku` | newest Luna | Haiku `low`–`medium`; Luna `low`, harder `medium`–`high` | small edits, docs, search, bulk work; fastest |

- Claude Code: pass the alias as `model` and the effort as `effort` on the Agent call. The
  alias resolves to the newest version.
- Codex: pass `model` and `model_reasoning_effort` on the spawn. Use the newest ID of the
  family the host shows, for example `gpt-6.1-sol`. Never use an ID from memory. Unknown ID:
  omit `model`, so the spawn inherits it, and record `inherited`. A custom agent file that
  sets `model` wins over the spawn value; record the file's value as effective.
- `xhigh` and `max` only where the notes show they help.
- Pick the role's tier and effort, then apply the notes. Take the lowest tier the notes show
  succeeding for this role and task kind.
- After a failed or rejected result, step up once: effort first, then tier. Never retry the
  same model and effort on the same failure.

## Model notes

Observed results beat vendor claims. The notes record what this project saw.

File: the profile's `model_notes`, default `.dev-cycle/model-notes.md` in the main
checkout. It is state, not work: never commit it. When `git check-ignore -q` fails, add
`.dev-cycle/` to `.git/info/exclude`. If the host cannot write `.git`, add it to `.gitignore`
in a commit instead. Only the coordinator writes the file; workers report to it.

Read it before the first delegation of a run. Append one log row after each delegated unit.

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
  `doc pass`.
- `outcome`: `ok`, `ok-after-fix` (the check sent it back once), `fail`, `escalated`.
- `minutes`: wall clock when known, else `-`.
- `note`: one fact, for example "missed the permission check", "invented an API".
- Over 40 log rows: fold the oldest into Summary (update `verdict`, `n`), then delete them.
- A Summary row with `n` ≥ 3 like-for-like observations overrides the vendor start values
  above for that role and task kind. Below 3 it is a hint.
- Only observations go here, never vendor claims.

Each final report lists role, model and effort per delegated unit and the rows added.
