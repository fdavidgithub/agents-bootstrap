#!/usr/bin/env bash

REPO="https://github.com/fdavidgithub/agents-bootstrap.git"
DIR='.agents-bootstrap'

git remote add agents-bootstrap $REPO
git fetch agents-bootstrap

# Exit immediately if a command exits with a non-zero status.
set -e

# Environment
mkdir -p $DIR

if [ ! -f .gitignore ]; then
    touch .gitignore
fi

grep -qxF $DIR .gitignore || echo $DIR >> .gitignore
grep -qxF AGENTS.md .gitignore || echo AGENTS.md >> .gitignore

# Shared files
mkdir -p /tmp/agents-bootstrap

git --work-tree=/tmp/agents-bootstrap restore \
  --source=agents-bootstrap/main \
  --worktree shared

cp -R /tmp/agents-bootstrap/shared/* $DIR/

## AGENTS.md
ln -sf $DIR/AGENTS.md AGENTS.md

# Template files (only copy if destination does not exist)
git --work-tree=/tmp/agents-bootstrap restore \
  --source=agents-bootstrap/main \
  --worktree templates

mkdir -p docs
cp -rn /tmp/agents-bootstrap/templates/. docs/

