#!/usr/bin/env bash
set -euo pipefail

# First-apply only. Re-apply manually via the deployed script:
#   ~/scripts/apply-macos-defaults.sh

SCRIPT="$HOME/scripts/apply-macos-defaults.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "⚠️  $SCRIPT not found or not executable — skipping macOS defaults" >&2
  exit 0
fi

"$SCRIPT"
