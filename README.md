# dev-cycle skills

Agent skills that take a feature from an intent to merged code through documents an agent can
pick up at any point: scenarios → workflow → task sequence → task files → execution and
validation in per-task git worktrees → merge. Format: [Agent Skills](https://agentskills.io/specification),
so the same files work in Claude Code and in Codex.

> Status: early, private. Extracted from a working monorepo; expect rough edges.

## What you type

```text
Claude Code:  /dev-cycle:cycle <intent or bundle path>     (plugin install)
              /cycle <intent or bundle path>               (linked into .claude/skills)
Codex:        $cycle <intent or bundle path>
```

`cycle` reads the bundle's files, works out the stage, runs the next skill and stops where it
needs you. Calling it again with the bundle path continues from the files, not from chat
memory.

| Option | Effect |
| --- | --- |
| `--until <stage>` | stop after `scenarios`, `workflow`, `sequence`, `drafts`, `detail`, `slices`, `validation` or `execution` |
| `--no-stop` | skip confirmation gates; real questions and failures still stop |

## Install

**Claude Code, as a plugin:**

```bash
claude plugin marketplace add <owner>/dev-cycle-skills   # or a local clone path
claude plugin install dev-cycle@dev-cycle-skills
```

Skills appear as `/dev-cycle:<name>`.

**Codex, or Claude Code without the plugin:**

```bash
git clone <repo-url> ~/src/dev-cycle-skills
~/src/dev-cycle-skills/scripts/install.sh codex-user                 # ~/.agents/skills
~/src/dev-cycle-skills/scripts/install.sh codex-project ~/src/my-app  # my-app/.agents/skills
~/src/dev-cycle-skills/scripts/install.sh claude-project ~/src/my-app # my-app/.claude/skills
```

The script symlinks every skill; they reference each other by sibling paths, so install them
together.

## Set up a project

Paste [`examples/AGENTS.dev-cycle.md`](examples/AGENTS.dev-cycle.md) into the project's root
`AGENTS.md` (or `CLAUDE.md`) and edit it. The skills never hardcode commands, branches or
paths: they read this `## Dev cycle` section and fall back to the defaults in
[`task-layout`](plugins/dev-cycle/skills/task-layout/SKILL.md#project-profile). A missing
command without a default makes the agent ask once.

## Example

Intent:

```text
/cycle add file upload on page X: the file is saved, then a notification about it goes to
the users of the project it was uploaded to, within the same organisation
```

What happens, stage by stage. Names below are illustrative; the agent takes real ones from
the code.

**Stop 1 — where the feature lives.** No bundle yet, so the agent proposes
`docs/tasks/<domain>/project-file-upload/` and waits for "yes" or another path.

**Stage 1 — scenarios, `00-interaction-scenarios.md`.** The intent names a page, so there is
a GUI. The document holds `S01` a project member uploads a file on page X; `S02` members of the
same project and organisation get a notification; `S03` a member from another organisation
gets nothing (negative); page states: empty, uploading, success, too large, wrong type, no
permission, network failure; open questions.

**Stop 2 — questions the plan cannot go without.** For example: size limit and file types;
channel (in-app, email, both); who counts as a project user; notify the uploader or not. One
line answers them ("50 MB, any type, in-app, all members, not the uploader"); answers are
recorded as decisions.

**Stage 2 — workflow, `01-workflow.md`.** Target model and invariants: a file is visible only
after it is stored and committed; recipients = project members ∩ project organisation − the
uploader; a notification goes out only after commit and never twice; nothing crosses to
another organisation. Plus an impact map of the layers that change.

**Stage 3 — task sequence, `02-task-sequence.md`.** A dependency graph with proof points,
roughly:

```text
T01 file model + storage ─► T02 upload API ─► T03 recipients + event ─► T04 in-app delivery
                               └─► T05 UI: upload on page X               └─► T06 UI: notification list
P01 after T01–T02: upload via API works, a foreign project gets 403
P02 after T03–T04: same-organisation members see the notification, others do not
P03 after T05–T06: the whole scenario in a browser
```

**Stages 4–7 — task files, `tasks/T01-…md` … `T06-…md`.** Four passes, each recorded as
`pass:` in frontmatter:

| Pass | Adds |
| --- | --- |
| `draft` | frontmatter, goal, scope, stub criteria |
| `detail` | check against code: what exists, contract, changes by layer, plan |
| `slices` | `S01…` items a subagent can do with small context and its own check |
| `validation` | each criterion becomes one case with an exact command |

No confirmations here; the agent stops only if the code contradicts the plan.

**Stop 3 — before implementation.** The agent shows the bundle branch, the order
(`T01 → T02 → T03 ∥ T05 → T04 → T06`, parallel only where code does not overlap), worktrees
and stands, and waits.

**Stage 8 — execution (`run-bundle`).** Per task: own worktree and branch, a worker runs
`execute-task` then `validate-task`, the coordinator reruns format, lint and tests itself and
merges the task branch into the bundle branch. A task waiting for another starts only after
that one is merged. Each closed `PNN` leaves a report in `evidence/`. Automatic stops: two
failed validations, a stale task, a code conflict at merge.

**Stop 4 — close.** All tasks validated, proof points closed: move the bundle to
`_completed/` and merge the bundle branch into the WIP branch? Production deployment is
outside these skills.

Result:

```text
docs/tasks/<domain>/project-file-upload/
  00-interaction-scenarios.md
  01-workflow.md
  02-task-sequence.md
  tasks/T01-file-model-storage_VAL.md … T06-notification-list-ui_VAL.md
  evidence/P01-….md  P02-….md  P03-….md
```

## Skills

| Skill | One step |
| --- | --- |
| `cycle` | router: detect the stage, run the next skill, stop at gates |
| `plan-scenarios` | GUI/TUI scenarios → `00-interaction-scenarios.md` |
| `plan-feature` | `01-workflow.md` and `02-task-sequence.md` (`workflow` / `sequence` / `all`) |
| `write-task` | task files; passes `draft`, `detail`, `slices`, `validation` |
| `execute-task` | implement one task file |
| `validate-task` | validate one finished task with proof per criterion |
| `run-bundle` | worktree per task, execute + validate, merge |
| `tidy-folder` | tidy a docs folder, move closed bundles, fix links |
| `task-layout` | contract: layout, IDs, frontmatter, language, project profile |
| `coding-rules` | contract: code structure rules `cs-001`…`cs-028` |

`write-task`, `run-bundle` and `tidy-folder` are hidden from automatic invocation in Claude
Code (`disable-model-invocation`); run them explicitly or let `cycle` run them.

## Language

People read about a tenth of these documents: purpose, scope, decisions, questions, risks,
verdicts, summaries. Those parts are written in the user's language. Everything for agents —
current-state tables, contracts, steps, subagent items, criteria mechanics, commands — is
compact English.

## Layout

```text
.claude-plugin/marketplace.json        Claude Code marketplace (this repo)
plugins/dev-cycle/.claude-plugin/       plugin manifest
plugins/dev-cycle/skills/<name>/SKILL.md
scripts/install.sh                      symlink skills for Codex or Claude without the plugin
examples/AGENTS.dev-cycle.md            project profile to paste into AGENTS.md
```

## License

Not chosen yet.
