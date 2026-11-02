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
