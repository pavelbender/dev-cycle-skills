---
name: tidy-folder
description: >-
  Tidy one documentation folder: classify files as canonical, active task, historical, index
  or noise; move closed cycles to _completed/; add or refresh the routing index; fix every
  inbound link. Use when asked to clean up, declutter or reorganise a docs folder
  («приберись в папке», «убери шум из docs/tasks/...», «разложи завершённые задачи»,
  "tidy docs folder").
argument-hint: "<folder-path> [goal]"
disable-model-invocation: true
metadata:
  contract: ../task-layout/SKILL.md
---

# Tidy a documentation folder

Input: a folder path inside the repository and, optionally, the goal (less noise from finished
tasks, one source of truth, simpler navigation). Claude Code passes `$ARGUMENTS`; Codex the
request text.

You are a structure editor, not an architect. Minimal, reversible, explicit changes. No new
hierarchy from scratch; no feature work mixed into the cleanup. The final summary is in the
user's language; the strategy block and file map are compact English.

## Principles

1. **Canonical over history.** The visible zone keeps guide, workflow, task sequence, open
   tasks and the index.
2. **History is not thrown away.** Finished tasks and implementation history move, they are
   not deleted, while they carry value.
3. **One source of truth.** If a `_DONE` file and a guide repeat a rule, the guide stays
   canonical and the historical file becomes secondary with a link.
4. **Minimality.** If an index and links remove the noise, files stay where they are.
5. **Fact over name.** `_DONE`/`_VAL` hint, they do not prove: check content and inbound links.
6. **Links never break.** Every move updates entry points and is verified by search.
7. **Layout per contract.** [`task-layout`](../task-layout/SKILL.md): a cycle moves
   to `_completed/` whole and only when closed; a partially done cycle stays with its `_DONE`
   files; `_rejected/` for rejected cycles; planning artefacts `00`/`01`/`02` get no suffix; IDs
   are never renumbered.

## Phase 1. Local context

Read root `AGENTS.md`, the nearest `AGENTS.md` of the area, the folder contents, the domain
`README.md` or index, 1–2 neighbouring entry documents. Find who links into the folder:
`grep -rn "<folder>" .` limited to docs and agent files.

## Phase 2. Content map

| Class | Meaning |
| --- | --- |
| `canonical` | guide, workflow, task sequence, ADR link, status document |
| `active-task` | task without `_DONE`/`_VAL` or in an open cycle |
| `historical-task` | finished task, evidence of a closed cycle, implementation history |
| `index` | README, status map, routing note |
| `draft/noise` | draft, duplicate, stale note without inbound links |

Per item: who links to it; should it stay visible; does it hold unique knowledge not yet
raised into canonical docs.

## Phase 3. One strategy

State it in chat before editing:

```text
Folder: <path>
Goal: <noise to remove>
Canonical: ...
Keep visible: ...
Move to _completed/ or archive: ...
Update links in: ...
Do not touch: ...
Verification: ...
```

Preference order: move nothing → move closed cycles to `_completed/` → collapse duplicates
with a link to canonical → delete only obvious junk (empty drafts, unreferenced duplicates).
Doubtful value → move, not delete. Folder already clean → say so, no fake reorganisation.

## Phase 4. Cleanup

Allowed: create `_completed/` or `archive/`; move closed cycles and historical files; add or
update the domain `README.md` (table: bundle → workflow, sequence, status); fix links in
`AGENTS.md`, guides, indexes, neighbours; add "canonical" / "historical" notes.

Forbidden: mass-rewriting task content; moving documents across initiatives without a stated
reason; fixing product gaps (that is a follow-up); losing out-of-scope and history that future
tasks rely on. Unique invariants from a historical file are raised into canonical first, then
the file moves.

Moves via `git mv` to keep history.

## Phase 5. Verification

1. Links from nearest `AGENTS.md`, `README.md`, indexes.
2. Old paths across the repo: `grep -rn "<old-path>"` over docs and agent files.
3. Orphans in the visible zone: nothing links to them, yet they add noise.
4. `git diff --check` and `git status` — nothing extra.

## Summary

Short: folder, strategy, what is canonical now, what moved, which links changed, which
follow-ups remain outside the cleanup. Not a changelog of every small edit.
