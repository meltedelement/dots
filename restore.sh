#!/usr/bin/env bash
# Copies this repo back over $HOME (repo -> live). Doesn't delete anything extra in $HOME.
# Use --dry-run first:  ./restore.sh --dry-run
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
rsync -rltE --omit-dir-times ${1:+"$1"} --itemize-changes "$REPO/home/" "$HOME/"
[[ "${1:-}" == "--dry-run" ]] || systemctl --user daemon-reload
