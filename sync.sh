#!/usr/bin/env bash

DIR='.agents-bootstrap'

# Exit immediately if a command exits with a non-zero status.
set -e

# Shared files
mkdir -p /tmp/agents-bootstrap

git fetch agents-bootstrap
git --work-tree=/tmp/agents-bootstrap restore \
  --source=agents-bootstrap/main \
  --worktree shared

cp -R /tmp/agents-bootstrap/shared/* $DIR/

# Template files (only copy if destination does not exist)
git --work-tree=/tmp/agents-bootstrap restore \
  --source=agents-bootstrap/main \
  --worktree templates

mkdir -p docs
cp -rn /tmp/agents-bootstrap/templates/. docs/

# Config folders (copied as hidden folders in the project root)
git --work-tree=/tmp/agents-bootstrap restore \
  --source=agents-bootstrap/main \
  --worktree config

"$(dirname "$0")/sync_config.sh" /tmp/agents-bootstrap/config

## .gitignore entries (source of truth: config/gitignore)
if [ ! -f .gitignore ]; then
    touch .gitignore
fi

while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    grep -qxF "$pattern" .gitignore || echo "$pattern" >> .gitignore
done < /tmp/agents-bootstrap/config/gitignore

