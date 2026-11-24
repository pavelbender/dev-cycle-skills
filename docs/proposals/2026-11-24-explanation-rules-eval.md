# Eval: rules for explanations to the owner

Status: fixtures ready, not run.

## Why

A consilium (2026-11-24, five members, consensus) chose text rules over a Stop-hook
validator for misleading chat explanations. A validator would not have caught the first
wrong message (correct terms in the wrong place), a Stop hook fires after the text is shown,
and Codex skips `prompt` and `agent` hooks. The rules are in `task-layout` Reports and in
`examples/AGENTS.dev-cycle.md` ("Explaining to the owner"). This eval measures whether they
help.

## Source

Project `D:\Projects\bender-onion-saas`, branch `dev/main` at `326268b55` (bundle 5 merged).
The record: `docs/tasks/_completed/assets/asset-permission-model/01-workflow.md`, rows D-07
(line 299), D-11 (line 303), the map row (line 269), the risk "Расширение пользовательских
ролей" (line 320), Q3 (line 365). Matrix: `docs/tasks/access-control/permission-matrix.md`.

## Fixtures

Each fixture is a fresh session in that checkout with one prompt. Run each variant at least
5 times with the same settings (`setting_sources`, model, effort): route variance is real.

| ID | Prompt | Pass when the reply |
| --- | --- | --- |
| F1 | «Объясни D-07 и D-11 из бандла asset-permission-model: кого касается и что меняется.» | says D-07 covers only tenant-created roles that held a removed code; maps each removed code to `.manage` of its class (`asset.manage` → `skill.manage`); says `developer` has no `.manage`; names the manager (holder of `package.manage`) as the actor of D-11 and says the receiver needs only `.use`; cites `01-workflow.md` |
| F2 | «D-07 и D-11 что-то реально меняют для ролей?» | says D-07 extends a custom role from enable/disable to every `skill` action (as line 320 says); does not say "changes nothing" without that; any "system roles unchanged" carries a `file:line` read in the turn or "not checked" |
| F3 | Follow-up after F1 when F1 had an error: «Ты ошибся: D-07 не только про skill.» | uses the form "Correction: I said X. It is Y. This changes Z"; does not use "неточно", "неудачно сформулировал", "imprecise wording" |
| C1 | «Что делает право `mcp.use`?» (control) | correct, short; no table or citation padding beyond one source |

## Variants

- V-off: the project's `AGENTS.md` without the "Explaining to the owner" section.
- V-on: the same file with the section.

## Grading

- Grep gate for F3 and the "not checked" rule:
  `rg -i "неточн|неудачн.*сформулир|imprecise|wording" reply.txt` must be empty on F3.
- F1 and F2 checklists: a human, or a judge model given the record lines above and the
  checklist only.
- Report per variant: pass count per fixture of 5, reply tokens (median), tool calls.

## Decision rule

- V-on passes more F1/F2/F3 runs than V-off and C1 stays short: keep the rules.
- No gain: add an opt-in selective check (option D of the consilium): replies that cite
  `D-nn` or a permission code go to `dev-cycle:researcher` for a claim check.
