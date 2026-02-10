#!/usr/bin/env bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
LOG="$HOME/$(basename "$0" .sh).log"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local msg="[$(timestamp)] $*"
  echo "$msg" >> "$LOG"

  # Print to terminal only if interactive
  if [[ -t 1 ]]; then
    echo "$msg"
  fi
}

run_cmd() {
  # Runs a command with proper logging + resilience
  if [[ -t 1 ]]; then
    if ! "$@" 2>&1 | tee -a "$LOG"; then
      log "WARN: command failed → $*"
      return 1
    fi
  else
    if ! "$@" >> "$LOG" 2>&1; then
      log "WARN: command failed → $*"
      return 1
    fi
  fi
}

log "Starting brew maintenance..."

# --------------------------------------------------
# Prevent running if another brew is active
# --------------------------------------------------
if pgrep -x brew >/dev/null 2>&1; then
  log "Brew already running. Skipping."
  exit 0
fi

# --------------------------------------------------
# Update brew metadata
# --------------------------------------------------
run_cmd brew update || true

# --------------------------------------------------
# Upgrade only leaf formulae
# --------------------------------------------------
LEAVES="$(brew leaves || true)"

if [[ -n "$LEAVES" ]]; then
  # shellcheck disable=SC2086
  run_cmd brew upgrade $LEAVES || true
else
  log "No leaf formulae to upgrade."
fi

# --------------------------------------------------
# Reinstall outdated casks safely
# --------------------------------------------------
OUTDATED_CASKS="$(brew outdated --cask --greedy --quiet || true)"

if [[ -n "$OUTDATED_CASKS" ]]; then
  log "Reinstalling outdated casks..."

  # Read safely line-by-line
  while IFS= read -r cask; do
    [[ -z "$cask" ]] && continue

    if ! run_cmd brew reinstall --cask "$cask"; then
      log "WARN: failed to reinstall cask → $cask"
    fi
  done <<< "$OUTDATED_CASKS"
else
  log "No outdated casks."
fi

# --------------------------------------------------
# Cleanup
# --------------------------------------------------
run_cmd brew autoremove || true
run_cmd brew cleanup || true

log "Brew maintenance complete."