# dev-cycle skills

Agent skills that take a feature from an intent to merged code through documents an agent can
pick up at any point: scenarios → workflow → task sequence → task files → execution and
validation in per-task git worktrees → merge. Format: [Agent Skills](https://agentskills.io/specification),
so the same files work in Claude Code and in Codex.

> Status: early, private. Extracted from a working monorepo; expect rough edges.

## What you type

```text
Claude Code:  /dev-cycle:cycle <intent or bundle path>
Codex:        $dev-cycle:cycle <intent or bundle path>
```

`cycle` reads the bundle's files, works out the stage, runs the next skill and stops where it
needs you. Calling it again with the bundle path continues from the files, not from chat
memory.

| Option            | Effect                                                                                                    |
| ----------------- | --------------------------------------------------------------------------------------------------------- |
| `--until <stage>` | stop after `scenarios`, `workflow`, `sequence`, `drafts`, `detail`, `slices`, `validation` or `execution` |
| `--no-stop`       | skip confirmation gates; real questions and failures still stop                                           |
| `--auto`          | autopilot: asks nothing, decides open questions itself and lists the decisions in the report; no push      |

## Install

Clone or copy this repository anywhere. Git, Claude Code and Codex must be on `PATH`.
The commands below use relative paths and work in PowerShell and Bash. Each section says
which directory to run them from. Keep the clone in place while using it as a marketplace.

This repository already contains its own marketplace catalogs for Claude and Codex.
Registering the local path adds that catalog to your client, then you install `dev-cycle`
from it. Anyone with a copy of the repository can install locally; publication in an
official public directory is optional and is only needed for discovery through that directory.

If you have not cloned the repository yet:

```sh
git clone https://github.com/pavelbender/dev-cycle-skills.git
cd dev-cycle-skills
```

Choose **one scope per client**. A user installation is available in all your projects; a
project installation enables the plugin only in that project. Both install the complete
plugin, including its fourteen skills, reference files and icon.

### Claude Code — user

Run from the root of the `dev-cycle-skills` clone:

```sh
claude plugin marketplace add ./ --scope user
claude plugin install dev-cycle@dev-cycle-skills --scope user
claude plugin details dev-cycle
```

The marketplace and enabled state are recorded in the user's Claude settings. Open a new
session and invoke `/dev-cycle:cycle`. `plugin details` should list fourteen skills.
Use `./` for the current directory: Claude Code 2.1.312 rejects a bare `.` as a marketplace source.

### Claude Code — project

Run from the target project's root. This example places the clone next to that project,
so its relative path is `../dev-cycle-skills`. Adjust that path if your folders differ:

```sh
claude plugin marketplace add ../dev-cycle-skills --scope project
claude plugin install dev-cycle@dev-cycle-skills --scope project
claude plugin details dev-cycle
```

This records the marketplace and enabled state in the project's `.claude/settings.json`.
Open a new session in that project and invoke `/dev-cycle:cycle`. Other collaborators must
have access to the marketplace and install the plugin on their machines too. A local path
is machine-specific; use the GitHub source below for shared project settings.

### Codex — user

Run from the root of the `dev-cycle-skills` clone:

```sh
codex plugin marketplace add .
codex plugin add dev-cycle@dev-cycle-skills
codex plugin list
```

This installs the plugin into Codex's user cache and enables it in `~/.codex/config.toml`
(or `$CODEX_HOME/config.toml` when configured). Open a new session and invoke
`$dev-cycle:cycle`. In the desktop app, restart the app to refresh the Plugins Directory.

### Codex — project

Codex has no `plugin add --scope project`. Merge the following tables into the target
project's `.codex/config.toml`. As in the Claude project example, this assumes the clone
is next to the target project. Start Codex from the target project's root when using this
relative `source`; adjust it if your folders differ.
An editable copy is in [`examples/codex-project.toml`](examples/codex-project.toml).
If either table already exists, update its keys instead of adding a duplicate table.

```toml
[marketplaces.dev-cycle-skills]
source_type = "local"
source = "../dev-cycle-skills"

[plugins."dev-cycle@dev-cycle-skills"]
enabled = true
```

Start Codex in the target project and accept its normal project trust prompt. Codex loads
project configuration only for trusted projects. The configured plugin is then copied to
the user cache during plugin refresh; its activation is controlled by this project's config.
Open a new session after the first refresh and invoke `$dev-cycle:cycle`. In the desktop
app, restart with that project open and check the plugin under **Dev Cycle Skills**.
The shared cache does not enable this project installation in other projects.

For this scope, use the project config above directly. Running `codex plugin add` enables
the plugin in user settings. If you previously installed it for the user, set
`enabled = false` in the existing `[plugins."dev-cycle@dev-cycle-skills"]` table in
`~/.codex/config.toml`; the project's `enabled = true` overrides it there.

### Install from GitHub

After the plugin changes have been pushed to GitHub, replace the local marketplace path in
the Claude and Codex user commands with `pavelbender/dev-cycle-skills`. For Codex project
settings, use `source_type = "git"` and
`source = "https://github.com/pavelbender/dev-cycle-skills.git"` in the marketplace table.
For Claude project settings, add the marketplace with the GitHub source and `--scope project`.
These sources can be committed without a machine-specific path.

### Check an installation

Validated locally with Claude Code **2.1.312** and Codex CLI **0.165.0**. Older clients may
not support these plugin commands; update the client if a command is missing.

```sh
# Run from the dev-cycle-skills clone root.
claude plugin validate --strict ./plugins/dev-cycle
claude plugin list
codex plugin marketplace list
```

Claude's `plugin details dev-cycle` lists the fourteen skills. In a Codex session, the skill
picker lists them as `dev-cycle:<name>`. `codex plugin list` is useful for user installations;
on Codex CLI 0.165.0 it does not report the project-only installation reliably, so verify
that scope from a session in the target project.

If you used the earlier symlink installer, remove only its dev-cycle links from
`.agents/skills` or `.claude/skills` before switching to the plugin, so the same skills do
not appear twice. `scripts/install.sh` remains an optional raw-skills installer; it does not
install the plugin or its icon.

## Update

For a marketplace installed from a **local clone**, first update it from the clone's root:

```sh
git pull --ff-only
```

When developing locally, your edits are already in the source clone; skip the pull.
For a marketplace registered directly from **GitHub**, use the marketplace refresh command
below instead of pulling a local clone.

Maintainers: increment `version` in **both** plugin manifests together when releasing plugin
changes. A GitHub push with the same version can leave users on the cached copy.

### Claude Code — user or project

For a GitHub marketplace, refresh its checkout first:

```sh
claude plugin marketplace update dev-cycle-skills
```

Then run the command for your installation scope:

| Scope   | Command                                                           | Run from            |
| ------- | ----------------------------------------------------------------- | ------------------- |
| User    | `claude plugin update dev-cycle@dev-cycle-skills --scope user`    | Any directory       |
| Project | `claude plugin update dev-cycle@dev-cycle-skills --scope project` | Target project root |

Open a new Claude session, then check `claude plugin details dev-cycle`. A marketplace
registered from a local directory loads that directory in place, so local edits become
available in a new session without publishing a release.

### Codex — user

For a GitHub marketplace, refresh its checkout first:

```sh
codex plugin marketplace upgrade dev-cycle-skills
```

For a local marketplace, update the source clone as described above. Then install the
current package from the refreshed marketplace:

```sh
codex plugin add dev-cycle@dev-cycle-skills
```

Restart Codex and check `codex plugin list`. Codex CLI 0.165.0 has no separate `plugin update`
command; `marketplace upgrade` refreshes Git sources, while `plugin add` installs the package.

### Codex — project

Update the local source clone, or run `codex plugin marketplace upgrade dev-cycle-skills`
**from the target project root** for a GitHub source. Keep the existing project's
`.codex/config.toml` tables and restart Codex in that trusted project. Plugin refresh
materializes the configured version in the shared cache. Check `$dev-cycle:cycle` in the
session's skill picker after the refresh.

Use the project config for activation; `codex plugin add` writes user-level activation.

### Refresh a Codex development build with the same version

Codex keeps a cached copy of the plugin. If local source edits are not picked up, close
sessions using this plugin and evict its cached installation:

```sh
codex plugin remove dev-cycle@dev-cycle-skills
```

For a **user** installation, run `codex plugin add dev-cycle@dev-cycle-skills` again.
For a **project** installation, leave its `enabled = true` setting in place and restart
Codex in that trusted project so plugin refresh installs the source again. If the first
session opens while refresh is still running, open a new session after it completes.
This cache is shared by projects, so eviction affects other sessions using the same plugin too.

## Uninstall

### Claude Code — user or project

Choose the scope you installed:

| Scope   | Command                                                              | Run from            |
| ------- | -------------------------------------------------------------------- | ------------------- |
| User    | `claude plugin uninstall dev-cycle@dev-cycle-skills --scope user`    | Any directory       |
| Project | `claude plugin uninstall dev-cycle@dev-cycle-skills --scope project` | Target project root |

Optionally unregister the marketplace from the **same scope** if you no longer use it:

```sh
claude plugin marketplace remove dev-cycle-skills --scope user
```

For a project marketplace, run from that project's root and use `--scope project` instead.
Open a new session and check `claude plugin list`. An installation in another scope can
still make the plugin available there.

### Codex — user

```sh
codex plugin remove dev-cycle@dev-cycle-skills
```

This removes the installed cache and the plugin's entry from user config. Optionally
unregister the user marketplace too:

```sh
codex plugin marketplace remove dev-cycle-skills
```

Restart Codex. Project settings that still enable the plugin can install it again in those
projects; remove those settings too if you want to stop using it everywhere.

### Codex — project

Remove the `[plugins."dev-cycle@dev-cycle-skills"]` and `[marketplaces.dev-cycle-skills]`
tables from that project's `.codex/config.toml`, preserving all other settings. Remove the
marketplace table only if no other plugin uses that marketplace. Restart Codex in the
project. The shared cache can remain for other projects; deleting it is unnecessary for
removing this project's installation.

If the plugin is also installed for the **user**, removing project settings falls back to
that user installation. To disable it only in this project, keep this override instead:

```toml
[plugins."dev-cycle@dev-cycle-skills"]
enabled = false
```

The lifecycle commands above apply to plugin installations. For skills linked by the old
`scripts/install.sh`, update by pulling the source clone and starting a new session; uninstall
by removing only those fourteen symlinks from the chosen `.agents/skills` or `.claude/skills`
directory. Keep the source clone until no remaining installation refers to it.

References: [Claude plugin management](https://code.claude.com/docs/en/discover-plugins),
[Codex plugin packaging and marketplaces](https://developers.openai.com/plugins/build/plugins).

## Set up a project

Paste [`examples/AGENTS.dev-cycle.md`](examples/AGENTS.dev-cycle.md) into the project's root
`AGENTS.md` (or `CLAUDE.md`) and edit it. The skills never hardcode commands, branches or
paths: they read this `## Dev cycle` section and fall back to the defaults in
[`task-layout`](plugins/dev-cycle/skills/task-layout/SKILL.md#project-profile). A missing
command without a default makes the agent ask once.

## Example

Intent:

```text
/dev-cycle:cycle add file upload on page X: the file is saved, then a notification about it goes to
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

| Pass         | Adds                                                                |
| ------------ | ------------------------------------------------------------------- |
| `draft`      | frontmatter, goal, scope, stub criteria                             |
| `detail`     | check against code: what exists, contract, changes by layer, plan   |
| `slices`     | `S01…` items a subagent can do with small context and its own check |
| `validation` | each criterion becomes one case with an exact command               |

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

| Skill            | One step                                                                     |
| ---------------- | ---------------------------------------------------------------------------- |
| `cycle`          | router: detect the stage, run the next skill, stop at gates                  |
| `plan-scenarios` | GUI/TUI scenarios → `00-interaction-scenarios.md`                            |
| `plan-feature`   | `01-workflow.md` and `02-task-sequence.md` (`workflow` / `sequence` / `all`) |
| `write-task`     | task files; passes `draft`, `detail`, `slices`, `validation`                 |
| `execute-task`   | implement one task file                                                      |
| `validate-task`  | validate one finished task with proof per criterion                          |
| `run-bundle`     | worktree per task, execute + validate, merge                                 |
| `tidy-folder`    | tidy a docs folder, move closed bundles, fix links                           |
| `autodebug`      | scheduled unattended agent: fix one known issue per run on its own branch    |
| `autobacklog`    | scheduled unattended agent: advance one current backlog item per run         |
| `collect-issues` | scheduled unattended agent: collect untracked problems into known issues     |
| `collect-backlog`| scheduled unattended agent: collect deferred and undone work into the backlog |
| `task-layout`    | contract: layout, IDs, frontmatter, language, project profile                |
| `coding-rules`   | contract: code structure rules `cs-001`…`cs-028`                             |

`write-task`, `run-bundle`, `tidy-folder` and the four unattended jobs are hidden from
automatic invocation in Claude Code (`disable-model-invocation`); run them explicitly or let
`cycle` run them.

## Unattended jobs

Each job installs a scheduled task per repository (Windows Task Scheduler, or a crontab line on
Linux and macOS) that runs a headless Claude Code agent (model pinned to `opus`, each run killed after 2 h):

| Job | Every | Default start | Does |
| --- | --- | --- | --- |
| `autodebug` | 30 min | spread, e.g. :07 | fixes one item of `known_issues` |
| `autobacklog` | 30 min | 15 min after `autodebug` | advances one current `backlog` item, new features through `cycle` |
| `collect-issues` | 6 h | 00:00 | adds untracked problems from docs, reports and code markers to `known_issues` |
| `collect-backlog` | 6 h | 03:00 | adds deferred and undone work from docs and bundles to `backlog` |

The two workers share a cap of two agents per machine; collectors are not capped. Every run
works in its own worktree and branch (collectors keep one rolling branch each,
`collect/known-issues` and `collect/backlog`, which the workers also read), writes a report
and a ledger row under `jobs_state`, and never pushes or merges: you review the reports and
merge the branches. Agents decide technical and small product questions themselves and stop
with a question only for architecture, business functionality or business-critical areas
(production, release, publish, secrets).

```text
/dev-cycle:autobacklog install      # also: dry-run, status, pause, resume, uninstall
/dev-cycle:autodebug install
/dev-cycle:collect-issues install   # -Hour N (--hour N on Linux, macOS) moves the 6-hour cycle
/dev-cycle:collect-backlog install
```

The agents run with `--permission-mode bypassPermissions`: unattended, they execute any
command as your user without asking, limited only by the job instructions. Install them
only on a machine and account where that is acceptable.

Add `known_issues`, `backlog` and optionally `jobs_state` and `job_notes` to the project
profile first. Tasks run the stable copy `~/.claude/agent-jobs/agent-job.ps1` (Windows, PowerShell 7)
or `agent-job.sh` (Linux and macOS, bash and cron), which reads the job text from the
installed plugin on every run, so plugin updates need no reinstall. Claude Code only; the jobs
need the plugin installation, not `scripts/install.sh`. On macOS cron may need Full Disk Access
and cannot always read the login keychain: if runs end with `exit 1, report missing` in the
ledger, read `logs/<stamp>.err.log` and `.jsonl` in the state directory.

## Language

People read about a tenth of these documents: purpose, scope, decisions, questions, risks,
verdicts, summaries. Those parts are written in the user's language. Everything for agents —
current-state tables, contracts, steps, subagent items, criteria mechanics, commands — is
compact English.

## Layout

```text
.claude-plugin/marketplace.json         Claude Code marketplace (this repo)
.agents/plugins/marketplace.json        Codex marketplace (this repo)
plugins/dev-cycle/.claude-plugin/       Claude plugin manifest
plugins/dev-cycle/.codex-plugin/        Codex plugin manifest
plugins/dev-cycle/assets/icon.png       shared plugin icon
plugins/dev-cycle/skills/<name>/SKILL.md
plugins/dev-cycle/agent-jobs/           runner, installer and shared rules of the unattended jobs
scripts/install.sh                      symlink skills for Codex or Claude without the plugin
examples/AGENTS.dev-cycle.md            project profile to paste into AGENTS.md
examples/codex-project.toml             Codex project installation settings
```

## License

[MIT](LICENSE).
