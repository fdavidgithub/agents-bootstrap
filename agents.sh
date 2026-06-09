#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${HOME}/.config/agent-bootstrap"
CONFIG_FILE="${CONFIG_DIR}/repo_path"

usage() {
    echo "Usage: $(basename "$0") {conf|init|sync}"
    exit 1
}

show_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Configured repository: $(<"$CONFIG_FILE")"
    else
        echo "Configured repository: <not configured>"
    fi
}

save_config() {
    read -r -p "Agent-bootstrap repository directory: " repo_dir

    if [[ -z "${repo_dir// }" ]]; then
        echo "Configuration unchanged."
        exit 0
    fi

    repo_dir="${repo_dir%/}"

    if [[ ! -d "$repo_dir" ]]; then
        echo "Error: directory not found: $repo_dir" >&2
        exit 1
    fi

    mkdir -p "$CONFIG_DIR"
    printf '%s\n' "$repo_dir" > "$CONFIG_FILE"

    echo "Configuration saved."
    echo "Configured repository: $repo_dir"
}

check_git_repository() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: the current directory is not a Git repository." >&2
        echo "The 'init' and 'sync' commands must be executed from within a Git repository." >&2
        exit 1
    fi
}

get_repo_dir() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: configuration not found. Run '$0 conf' first." >&2
        exit 1
    fi

    cat "$CONFIG_FILE"
}

run_script() {
    local script_name="$1"
    local repo_dir

    repo_dir="$(get_repo_dir)"

    if [[ ! -x "$repo_dir/$script_name" ]]; then
        echo "Error: script not found or not executable:" >&2
        echo "  $repo_dir/$script_name" >&2
        exit 1
    fi

    "$repo_dir/$script_name"
}

[[ $# -eq 1 ]] || usage
show_config

case "$1" in
    conf)
        save_config
        ;;
    init)
        check_git_repository
        run_script "init.sh"
        ;;
    sync)
        check_git_repository
        run_script "sync.sh"
        ;;
    *)
        usage
        ;;
esac


