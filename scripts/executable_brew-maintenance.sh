#!/bin/bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

LOG="$HOME/$(basename "$0" .sh).log"
LOG_MAX_BYTES=5242880  # 5 MiB
LOCK="$HOME/.cache/brew-maintenance.lock"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local msg
  msg="[$(timestamp)] $*"

  if [[ -f "$LOG" && $(stat -f%z "$LOG" 2>/dev/null || echo 0) -gt $LOG_MAX_BYTES ]]; then
    mv "$LOG" "$LOG.1"
  fi

  echo "$msg" >> "$LOG"

  if [[ -t 1 ]]; then
    echo "$msg"
  fi
}

run_cmd() {
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
# Mutual exclusion via shlock (stale-PID safe)
# --------------------------------------------------
mkdir -p "$(dirname "$LOCK")"
if ! /usr/bin/shlock -f "$LOCK" -p $$ >/dev/null 2>&1; then
  log "Another brew job is running (lock: $LOCK). Skipping."
  exit 0
fi
trap 'rm -f "$LOCK"' EXIT

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
