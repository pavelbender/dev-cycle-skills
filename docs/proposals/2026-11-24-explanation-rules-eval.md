# Eval: rules for explanations to the owner

Status: run 2026-11-24 (sonnet, medium, `--setting-sources project`); rules kept.

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
| F2 | «D-07 и D-11 что-то реально меняют для ролей?» | says D-07 extends a custom role from enable/disable to every `skill` action (as line 320 says); does not present D-11 as a pure rename: per line 303 it changes INV-3 of bundle 2; any "system roles unchanged" carries a `file:line` read in the turn or "not checked"; cites the record path |
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

## Results (2026-11-24)

Harness: `D:\Projects\onion-stand\chat\` (`run-chat.sh <off|on> <fixture> <n>`, blind judge
`judge.sh` on sonnet low with `truth.md` and `criteria.tsv`; grades in `grades*.txt`).
Tools in the answering session: read and search only.

| Fixture | off (pass) | on (pass) | Item that moved |
| --- | --- | --- | --- |
| F1 | 0/5 | 0/5 | D-07 scope 0/5 → 3/5; D-11 actor 0/5 in both |
| F2 | 0/5 | 3/5 | record path cited 0/5 → 5/5 |
| F3 | 2/5 | 5/5 | consequence stated 2/5 → 5/5; softening absent in both |
| C1 | 0/3 | 3/3 | `on` read the catalog and got the holders right |

Mean cost per reply: off $0.107, on $0.108. Output tokens: about equal on F1, +30% on F2,
+20% on F3, +75% on C1 (the reply read the catalog instead of guessing).

Findings:

- The original agent's claim about D-11 ("the rule is the same, only the code name
  changed") is itself contradicted by line 303 ("Меняет INV-3 бандла 2"). The first draft of
  criterion F2 b copied that claim and was corrected before grading.
- D-11 actor (manager vs receiver) fails in every variant. The record names the rights but
  not the receiver; the agent cannot cite what the record does not say. A stronger rule
  wording ("name who acts and who is only affected") was tried: F1 0/5, F2 1/5. Reverted.
  The fix belongs in the record: a decision row on rights names the actor and the affected
  roles.
- n = 5 per cell, one judge: direction, not a rate.

### Follow-up: actor in the record

Variant `rec`: rules on, plus one sentence in the D-11 row naming the actor (holder of
`package.manage`) and the affected (receivers need only `<class>.use`, enable nothing).
F1: 4/5 pass, D-11 actor 5/5 (was 0/5), D-07 scope 4/5. Cost per reply $0.150 (on: $0.101),
because the reply now explains the actor. Adopted: `plan-feature` asks rights decisions for
"Actor: … Affected: …".
