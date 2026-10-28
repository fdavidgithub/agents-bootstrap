#!/usr/bin/env bash
#
# Exposes the skills distributed to .agents-bootstrap/skills to the agent tools
# by symlinking each tool's skills folder to it.
#
# Usage: link_skills.sh   (run from the project root)
#
#   .claude/skills  -> ../.agents-bootstrap/skills   (Claude Code, opencode)
#   .agents/skills  -> ../.agents-bootstrap/skills   (Codex and others)
#
# A real (non-symlink) skills folder is never replaced: it is skipped with a
# warning.

set -euo pipefail

DIR='.agents-bootstrap'
TARGET="../${DIR}/skills"

[ -d "${DIR}/skills" ] || exit 0

touch .gitignore

for tool in .claude .agents; do
    mkdir -p "$tool"
    link="$tool/skills"

    if [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "Skipping $link: exists and is not a symlink" >&2
        continue
    fi

    ln -sfn "$TARGET" "$link"
    grep -qxF "$tool" .gitignore || echo "$tool" >> .gitignore
done
