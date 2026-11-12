# Anthropic reference pages

The Anthropic documentation pages the dev-cycle skills were tuned against, as of 2026-11-12.
The pages themselves are not in this repository: they belong to Anthropic and are not covered
by this repository's MIT license, so `.gitignore` excludes them. Only this index is tracked.
Fetch local copies with the command under [Refresh](#refresh) when you work on the skills.

The plugin does not read the pages: the installed plugin contains only `plugins/dev-cycle`, so
a skill never links here. What the skills need from them is restated in
[`roles-and-models.md`](../../plugins/dev-cycle/skills/task-layout/references/roles-and-models.md).

## Pages

Prompting, from `https://platform.claude.com/docs/en/`:

| File | Source path |
| --- | --- |
| `prompt-engineering-overview.md` | `build-with-claude/prompt-engineering/overview` |
| `claude-prompting-best-practices.md` | `build-with-claude/prompt-engineering/claude-prompting-best-practices` |
| `prompting-claude-fable-5-2.md` | `build-with-claude/prompt-engineering/prompting-claude-fable-5-2` |
| `prompting-claude-opus-5-5.md` | `build-with-claude/prompt-engineering/prompting-claude-opus-5-5` |
| `prompting-claude-sonnet-5-5.md` | `build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5` |
| `prompting-claude-haiku-5-5.md` | `build-with-claude/prompt-engineering/prompting-claude-haiku-5-5` |
| `effort.md` | `build-with-claude/effort` |
| `agent-skills-best-practices.md` | `agents-and-tools/agent-skills/best-practices` |
| `choosing-a-model.md` | `about-claude/models/choosing-a-model` |
| `models-overview.md` | `models/overview` |

Claude Code, from `https://code.claude.com/docs/en/`:

| File | Source path |
| --- | --- |
| `claude-code-sub-agents.md` | `sub-agents` |
| `claude-code-agents.md` | `agents` |
| `claude-code-agent-teams.md` | `agent-teams` |
| `claude-code-workflows.md` | `workflows` |
| `claude-code-skills.md` | `skills` |
| `claude-code-model-config.md` | `model-config` |
| `claude-code-best-practices.md` | `best-practices` |

## Refresh

Append `.md` to a source path to get the page as Markdown. From this directory:

```sh
get() { curl -sL -A "Mozilla/5.0" -o "$1" "$2.md"; }
p=https://platform.claude.com/docs/en; c=https://code.claude.com/docs/en
get prompt-engineering-overview.md      $p/build-with-claude/prompt-engineering/overview
get claude-prompting-best-practices.md  $p/build-with-claude/prompt-engineering/claude-prompting-best-practices
for m in fable-5-2 opus-5-5 sonnet-5-5 haiku-5-5; do
  get prompting-claude-$m.md            $p/build-with-claude/prompt-engineering/prompting-claude-$m
done
get effort.md                           $p/build-with-claude/effort
get agent-skills-best-practices.md      $p/agents-and-tools/agent-skills/best-practices
get choosing-a-model.md                 $p/about-claude/models/choosing-a-model
get models-overview.md                  $p/models/overview
for d in sub-agents agents agent-teams workflows skills model-config best-practices; do
  get claude-code-$d.md                 $c/$d
done
```

After a refresh, reread the rows below and update the skills where a page changed.

## What the skills take from each page

| Statement in the pages | Where the plugin applies it |
| --- | --- |
| Effort is the main control for thinking, tool calls, latency and cost; levels are calibrated per model (`effort.md`, the four model pages) | role and tier effort values, "Claude Code models" in `roles-and-models.md` |
| In Claude Code all four models default to `medium`; a subagent on another model does not inherit the session's effort (`claude-code-model-config.md`, `claude-code-sub-agents.md`) | "pass `model` and `effort` on every Agent call" |
| Fable 5.2: `high` carries most of the gain; `low` suits fast subagents; `xhigh` only with a measured gain | deep tier starts at `high`; workers capped at `high` |
| Fable 5.2 delegates more when prompts invite it; say what a subagent costs, when it pays, how to brief | one "When to delegate" section; skills name only their fan-out points |
| Fable 5.2: a token budget shown to the model changes what it spends | unit size is a planning target; briefs carry no token numbers |
| Fable 5.2 treats "never" as absolute; write scope and reason | reasons next to constraints in the brief; plain imperatives in `coding-rules` |
| Fable 5.2, Sonnet 5.5, Haiku 5.5 stop early at `low` and `medium`; Opus 5.5 can end a turn on a progress report | the "keep working" line in every brief; autopilot and unattended-job text about how turns end |
| Sonnet 5.5 and Haiku 5.5 can report a change done without a real check at lower effort | the "real check" line for workers that change code; QA developer at `high` |
| Sonnet 5.5 at `xhigh` and `max` starts its own review rounds and reviewer subagents | workers go no higher than `high`; "do not start reviewer subagents" |
| Haiku 5.5 costs more per token on prompts over 100K tokens | light-tier unit target of about 100 thousand tokens |
| Requests to reproduce reasoning in the reply can be refused (`reasoning_extraction`) | briefs and the consilium return format ask for position, evidence and risks |
| Final reports are read without the tool calls behind them | "Reports" in `task-layout` |
| Subagents nest three layers below the main conversation by default; 20 run at once (`claude-code-sub-agents.md`) | "Layers" in `roles-and-models.md`; wave width of 5 |
| Independent investigators with distinct lenses, then a challenge round, beat one anchored pass (`claude-code-agent-teams.md`) | the `consilium` skill |
| Keep `SKILL.md` under 500 lines, references one level deep, a table of contents in long references (`agent-skills-best-practices.md`) | file layout of the skills |
