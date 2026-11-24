## Dev cycle

<!-- Project profile read by the dev-cycle skills. Paste into the root AGENTS.md and edit. -->

- tasks_root: docs/tasks/
- decisions: docs/adr/
- glossary: docs/glossary.md
- format: uv run ruff format .
- lint: uv run ruff check .
- test: uv run pytest {path} -q
- stand: make up / make smoke
- wip_branch: main
- bundle_branch: feat/{bundle}
- task_branch: feat/{bundle}-{task}
- worktree_root: ../{repo}.worktrees/
- worktree_setup: uv sync --frozen
- task_heading: "# Task:"
- boundaries: Services never import each other; shared contracts live in packages/contracts.
- known_issues: docs/known-issues.md
- backlog: docs/BACKLOG.md
- jobs_state: .dev-cycle/jobs/
- job_notes: docs/agent-jobs.md
- probe_notes: docs/probe-notes.md
- model_notes: .dev-cycle/model-notes.md

## Explaining to the owner

<!-- Applies to every reply, with or without a dev-cycle skill loaded. -->

- Explaining a recorded decision, permission or contract: read the record again first. Cite
  its ID and path. State who acts, on what, with which right.
- "Unchanged", "verified", "no effect": name the `file:line` you read in this turn, or write
  "not checked".
- A wrong statement of yours: write "Correction: I said X. It is Y. This changes Z for your
  decision." Never call a factual error wording.
- "Check claims": hand the claims of your last reply to a fresh read-only agent
  (`dev-cycle:researcher` where the host has it). Relay its `file:line` or "not confirmed"
  per claim.
