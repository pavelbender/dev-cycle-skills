#!/usr/bin/env bash
# Link the dev-cycle skills into a skills directory.
#   install.sh codex-user              -> ~/.agents/skills/<name>
#   install.sh codex-project <repo>    -> <repo>/.agents/skills/<name>
#   install.sh claude-project <repo>   -> <repo>/.claude/skills/<name>
#   install.sh claude-user             -> ~/.claude/skills/<name>
# All skills are linked together: they reference each other by sibling paths (../task-layout).
set -euo pipefail
src="$(cd "$(dirname "$0")/../plugins/dev-cycle/skills" && pwd)"
case "${1:-}" in
  codex-user)     dest="$HOME/.agents/skills" ;;
  codex-project)  dest="${2:?repo path required}/.agents/skills" ;;
  claude-user)    dest="$HOME/.claude/skills" ;;
  claude-project) dest="${2:?repo path required}/.claude/skills" ;;
  *) sed -n '2,7p' "$0"; exit 2 ;;
esac
mkdir -p "$dest"
for dir in "$src"/*/; do
  name="$(basename "$dir")"
  if [ -e "$dest/$name" ] && [ ! -L "$dest/$name" ]; then
    echo "skip $dest/$name: exists and is not a symlink" >&2; continue
  fi
  ln -sfn "${dir%/}" "$dest/$name"
  echo "linked $dest/$name"
done
