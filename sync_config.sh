#!/usr/bin/env bash
#
# Distributes each subdirectory of a config source directory as a hidden
# folder in the current project root.
#
# Usage: sync_config.sh <config_source_dir>
#
# For each subdirectory <tool>/ under <config_source_dir>, copies its
# contents to .<tool>/ in the current directory. If the destination folder
# already exists and stdin is a terminal, prompts once per folder:
#   [O]verwrite, [S]kip, [A]bort
# In non-interactive contexts (e.g. the post-merge hook) existing folders
# are overwritten without prompting.
#
# Exception: opencode/ is copied flat into the project root (not into
# .opencode/). opencode only reads project config from opencode.json at the
# repo root; a nested .opencode/ folder is treated by opencode as a
# plugin/agent directory, causing it to write its own package.json and run
# `bun install` (creating node_modules) on every startup, while the config
# inside it is silently ignored.

set -euo pipefail

SRC_CONFIG="${1:?Usage: sync_config.sh <config_source_dir>}"

shopt -s nullglob

confirm_overwrite() {
    local dest="$1"

    if [ -e "$dest" ] && [ -t 0 ]; then
        printf 'Destination "%s" already exists. ' "$dest"
        read -r -p "[O]verwrite, [S]kip, [A]bort? " ans || { echo "Aborted." >&2; exit 1; }
        case "$ans" in
            [oO]) return 0 ;;
            [aA]) echo "Aborted." >&2; exit 1 ;;
            *)    echo "Skipping $dest"; return 1 ;;
        esac
    fi

    return 0
}

for src in "$SRC_CONFIG"/*/; do
    dir_name="$(basename "$src")"

    if [ "$dir_name" = "opencode" ]; then
        for file in "$src"*; do
            [ -f "$file" ] || continue
            dest="$(basename "$file")"

            confirm_overwrite "$dest" || continue

            cp "$file" "$dest"
            grep -qxF "$dest" .gitignore || echo "$dest" >> .gitignore
        done
        continue
    fi

    dest=".$dir_name"

    confirm_overwrite "$dest" || continue

    mkdir -p "$dest"
    cp -R "$src". "$dest"/
    grep -qxF "$dest" .gitignore || echo "$dest" >> .gitignore
done
