#!/usr/bin/env bash

#Exit immediately if a command exits with a non-zero status.
set -e

PROMPTS_REPO="https://github.com/sua-org/ai-prompts.git"
TMP_DIR=$(mktemp -d)

git clone --depth=1 "$PROMPTS_REPO" "$TMP_DIR"

mkdir -p .agents/shared

cp -R "$TMP_DIR/shared/"* .agents/shared/

rm -rf "$TMP_DIR"

git fetch prompts-origin
git restore --source prompts-origin/main shared/git.md
git restore --source prompts-origin/main shared/commits.md
git restore --source prompts-origin/main shared/code-review.md
echo "Prompts sincronizados."

