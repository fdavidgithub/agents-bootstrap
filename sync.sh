#!/usr/bin/env bash

DIR='.agents-bootstrap'

# Exit immediately if a command exits with a non-zero status.
set -e

# Shared files
mkdir -p /tmp/agents-bootstrap

git --work-tree=/tmp/agents-bootstrap restore \
  --source=agents-bootstrap/main \
  --worktree shared

cp -R /tmp/agents-bootstrap/shared/* $DIR/

