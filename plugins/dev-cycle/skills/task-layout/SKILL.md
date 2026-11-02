---
name: task-layout
description: >-
  Contract for development-cycle documents: feature bundle layout (scenarios, workflow, task
  sequence, task files, evidence), TNN/PNN/SNN identifiers, task-file frontmatter and status
  suffixes, readiness, language of artifacts, and the project profile the other dev-cycle
  skills read. Use when creating, classifying, renaming or checking task documents, or when
  another dev-cycle skill points here.
metadata:
  role: contract
---

# Task layout contract

Every other skill of this set (`cycle`, `plan-scenarios`, `plan-feature`, `write-task`,
`execute-task`, `validate-task`, `run-bundle`, `tidy-folder`, `autodebug`, `autobacklog`,
`collect-issues`, `collect-backlog`) follows this contract. It keeps
scenarios, workflows, task sequences, implementation tasks and evidence of one feature in one
group instead of a flat numbered list.

## Project profile

Project-specific facts come from the project, never from these skills. Read them from a
`## Dev cycle` section of the root `AGENTS.md` (or `CLAUDE.md` when there is no `AGENTS.md`).
Missing key → default below. A missing command with no default → ask, never guess.

```markdown
## Dev cycle

- tasks_root: docs/tasks/                 # where bundles live
- decisions: docs/adr/                    # ADRs or equivalent; "none" if the project has none
- glossary: docs/glossary.md              # normative domain terms, if any
- format: <command>                       # e.g. uv run ruff format .
- lint: <command>                         # e.g. uv run ruff check .
- test: <command with {path}>             # e.g. uv run pytest {path} -q
- stand: <up command> / <smoke command>   # optional: runtime environment for runtime tasks
- wip_branch: main                        # where finished bundles land
- bundle_branch: feat/{bundle}            # per-bundle integration branch
- task_branch: feat/{bundle}-{task}       # per-task branch
- worktree_root: ../{repo}.worktrees/     # where task worktrees are created
- worktree_setup: <command>               # optional: install deps in a fresh worktree
- task_heading: "# Task:"                 # heading that marks an implementation task file
- tracker_key: jira_link                  # optional frontmatter key for a tracker link
- boundaries: <one line>                  # optional: rule every subagent brief must carry
- known_issues: docs/known-issues.md      # optional: open defects; fed by collect-issues, worked by autodebug
- backlog: docs/BACKLOG.md                # optional: routing index of bundles; fed by collect-backlog, worked by autobacklog
- jobs_state: .dev-cycle/jobs/            # optional: ledgers, reports, logs of the unattended jobs
- job_notes: docs/agent-jobs.md           # optional: project specifics for unattended jobs
```

| Key | Default |
| --- | --- |
| `tasks_root` | `docs/tasks/` |
| `decisions` | whatever `AGENTS.md` routes to; none → decisions are recorded in the workflow |
| `wip_branch` | the repository default branch |
| `bundle_branch` | `feat/{bundle}` |
| `task_branch` | `feat/{bundle}-{task}` (lowercase task ID) |
| `worktree_root` | `../{repo}.worktrees/`, directory name = branch with `/` → `-` |
| `task_heading` | `# Task:` |
| `format`, `lint`, `test` | none: ask once, then suggest adding them to the profile |
| `known_issues` | none: `autodebug` looks only at recent evidence follow-ups; `collect-issues` cannot run |
| `backlog` | none: `autobacklog` scans open bundles under `tasks_root`; `collect-backlog` cannot run |
| `jobs_state` | `.dev-cycle/jobs/`; `install` adds it to `.git/info/exclude` when not ignored |
| `job_notes` | none: skip lists, live environments, stand ports and branch names for the unattended jobs |

Nearest local `AGENTS.md` files override the root one for files under them.

## Terms

- **Domain root** — the documentation area of a product domain, e.g. `<tasks_root>/billing`.
- **Feature bundle** — one directory with the planning, task and evidence artifacts of one
  feature or bounded change.
- **Planning artifact** — interaction scenarios, umbrella workflow or task sequence. Not a task.
- **Implementation task** — a file with a stable task ID, frontmatter, and `task_heading`.
- **Evidence artifact** — a proof-point report, validation result or incident report that
  proves one or more tasks.

## When a bundle is required

Create a bundle when any holds: scenarios will feed a workflow and sequence; both a workflow
and a sequence are created; separate task files will be created from a sequence; the feature
needs proof-point artifacts. Do not wrap one standalone document in a bundle. Do not create a
parallel bundle for an existing document family: keep its layout, or migrate the whole family
and all references in one change.

## Layout

```text
<tasks_root>/<domain>/<feature-slug>/
  00-interaction-scenarios.md   # optional
  01-workflow.md
  02-task-sequence.md
  tasks/
    T01-<task-slug>.md
    T02-<task-slug>_DONE.md
    T03-<task-slug>_VAL.md
  evidence/
    P01-<proof-slug>.md
  _completed/                   # at domain level: closed bundles, moved whole
```

The feature slug lives in the directory name, not in every filename. `tasks/` and `evidence/`
appear when they get files. `00`/`01`/`02` order planning artifacts only; they are not task
IDs and never continue as task numbers. A domain with more than one bundle keeps a
`README.md` index: bundle → workflow, sequence, status.

## Identifiers

- `TNN` — implementation tasks; `PNN` — proof points and their evidence files; `SNN` —
  subagent-ready items inside one task.
- IDs are copied from `02-task-sequence.md`, never derived from the next free filename.
- Published IDs are never renumbered.
- `_DONE` and `_VAL` are task lifecycle suffixes only; planning artifacts never get them.

## Task file frontmatter

```yaml
---
id: T02                 # TNN, equals the ID in the filename and in 02-task-sequence.md
status: done            # formed | in_progress | review | done | validated | withdrawn
blocked_by: [T01]       # = Depends on column of 02-task-sequence.md; task codes only
blocks: [T05, T08]      # = Unlocks column; task codes only
milestone: P01          # optional: PNN from 02-task-sequence.md
pass: validation        # optional: last write-task pass: draft | detail | slices | validation
# assigned_to: alice    # optional: only when the bundle has more than one contributor
# jira_link: https://…  # optional: tracker link under the profile's tracker_key
---
```

Rules:

- The opening `---` is line 1; the block closes with `---` on its own line.
- Scalars and flow lists (`[a, b]`) only; no block lists, no nested maps. Tools that read the
  block may use a line-based parser. A trailing ` # comment` is allowed.
- `id`, `status`, `blocked_by`, `blocks` are required; the rest are optional. Empty set: `[]`.
- `assigned_to` only in bundles with more than one contributor; a solo project omits it.
- A tracker link is optional and tracker-specific; its key comes from the profile.
- `status` ⇔ suffix: `done` ⇔ `_DONE`, `validated` ⇔ `_VAL`, others ⇔ no suffix. A task may go
  from no suffix straight to `_VAL` when acceptance and validation coincide.
- `blocked_by` ⇔ `Depends on`, `blocks` ⇔ `Unlocks` in `02-task-sequence.md`, which stays the
  source of truth; a mismatch is a defect of the task file.
- Readiness is derived: ready when every code in `blocked_by` is `done` or `validated`.
- `pass` is written by `write-task` after each pass and read by `cycle`.
- Human detail (reviewer, date, link to evidence) lives in a `**Status:**` line under the
  heading; frontmatter carries the enum only.

| `status` | Meaning |
| --- | --- |
| `formed` | specified, not started |
| `in_progress` | being implemented |
| `review` | implemented, waits for review or acceptance |
| `done` | accepted; file renamed `_DONE` |
| `validated` | validated after completion; file renamed `_VAL` |
| `withdrawn` | dropped by decision; not counted in readiness |

Files without frontmatter (older tasks): `status` from the suffix, `blocked_by` from the
sequence. Add frontmatter when the file is next touched.

## Language of artifacts

The user reads roughly a tenth of any artifact: purpose, boundaries, decisions, open
questions, risks, verdicts, summaries. Those parts are written in the user's language.
Everything written for agents — current-state tables, target contracts, changes by layer,
implementation steps, subagent items, acceptance-criteria mechanics, test and verification
commands, validation matrices — is compact English. Section headings: keep the names a bundle
already uses; in a new project use the template names or translate them once. Identifiers,
paths, commands and error text are verbatim in every language.

## Readiness

File order does not define execution order. A formed task is **ready** only when its whole
`Depends on` set is complete or an explicitly accepted existing contract; otherwise it is
**blocked**, even when it is the lowest unfinished number. Several tasks may be ready at once.
Pick the next task from the graph and the target milestone. Say "dependency predecessors",
not "previous task", unless the graph has exactly one.

## Artifact classification

| Class | Signal | Meaning |
| --- | --- | --- |
| `guide` | reference document without `task_heading` | shared domain context |
| `scenario` | `00-interaction-scenarios.md` | interaction planning |
| `workflow` | `01-workflow.md` | target behaviour and model |
| `task-sequence` | `02-task-sequence.md` | task IDs, dependencies, proof points |
| `formed` | `tasks/TNN-*.md` with `task_heading`, no suffix | specified; readiness from the graph |
| `done` | `_DONE` or `_VAL` suffix | implemented; verify against repository truth |
| `evidence` | file under `evidence/` | proof, not a task |
| `draft` | anything else | review explicitly; never treat as a task by its number |

## Linking

- `00-interaction-scenarios.md` links to the workflow it prepares.
- `01-workflow.md` links back to the scenarios and forward to `02-task-sequence.md`.
- `02-task-sequence.md` is the source of truth for `TNN`, `PNN`, `Depends on`, task and
  evidence paths.
- Every task links to its sequence and its direct dependency tasks.
- Every evidence file names its `PNN` and the `TNN` it proves.

## Existing flat document families

Do not move or renumber published files because this contract appeared. New work in a
populated flat directory: update the existing family in place when the work belongs to it,
otherwise create a bundle; never allocate the next global `NN` across artifact kinds. An
explicit migration moves the whole family, fixes every inbound and outbound reference and
routing index, and ends with a reference sweep and `git diff --check`.
