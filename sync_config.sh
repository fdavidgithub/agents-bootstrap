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

set -euo pipefail

SRC_CONFIG="${1:?Usage: sync_config.sh <config_source_dir>}"

shopt -s nullglob

for src in "$SRC_CONFIG"/*/; do
    dir_name="$(basename "$src")"
    dest=".$dir_name"

    if [ -e "$dest" ]; then
        if [ -t 0 ]; then
            printf 'Destination "%s" already exists. ' "$dest"
            read -r -p "[O]verwrite, [S]kip, [A]bort? " ans || { echo "Aborted." >&2; exit 1; }
            case "$ans" in
                [oO]) : ;;
                [aA]) echo "Aborted." >&2; exit 1 ;;
                *)    echo "Skipping $dest"; continue ;;
            esac
        fi
    fi

    mkdir -p "$dest"
    cp -R "$src". "$dest"/
    grep -qxF "$dest" .gitignore || echo "$dest" >> .gitignore
done
