#!/bin/bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

LOG="$HOME/$(basename "$0" .sh).log"
LOG_MAX_BYTES=5242880  # 5 MiB
BREW_LOCK="$HOME/.cache/brew-maintenance.lock"  # shared with brew-maintenance.sh

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

log "Starting quarterly deep clean..."

# --------------------------------------------------
# Docker cleanup
# --------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  log "Cleaning Docker..."
  START=$(date +%s)
  run_cmd docker system prune -af --volumes || true
  END=$(date +%s)
  log "Docker cleanup duration: $((END - START))s"
fi

# --------------------------------------------------
# Xcode DerivedData (safe reset)
# --------------------------------------------------
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
if [[ -d "$DERIVED" ]]; then
  log "Resetting Xcode DerivedData..."
  rm -rf -- "$DERIVED"
  mkdir -p "$DERIVED"
fi

# --------------------------------------------------
# Remove unavailable simulators
# --------------------------------------------------
if command -v xcrun >/dev/null 2>&1; then
  log "Cleaning simulators..."
  run_cmd xcrun simctl delete unavailable || true
fi

# --------------------------------------------------
# Brew deep cleanup (guarded by shared brew lock)
# --------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  mkdir -p "$(dirname "$BREW_LOCK")"
  if /usr/bin/shlock -f "$BREW_LOCK" -p $$ >/dev/null 2>&1; then
    trap 'rm -f "$BREW_LOCK"' EXIT

    log "Brew deep cleanup..."
    run_cmd brew cleanup -s || true

    BREW_CACHE="$HOME/Library/Caches/Homebrew"
    if [[ -d "$BREW_CACHE" ]]; then
      log "Clearing Homebrew cache..."
      rm -rf -- "$BREW_CACHE"
      mkdir -p "$BREW_CACHE"
    fi

    rm -f "$BREW_LOCK"
    trap - EXIT
  else
    log "Brew lock held by another process. Skipping brew section."
  fi
fi

# --------------------------------------------------
# Clear rotated logs only
# --------------------------------------------------
LOG_DIR="$HOME/Library/Logs"
if [[ -d "$LOG_DIR" ]]; then
  log "Clearing logs older than 30 days..."

  if [[ -t 1 ]]; then
    find "$LOG_DIR" -type f -mtime +30 -print -delete 2>&1 | tee -a "$LOG" || log "WARN: log cleanup failed"
  else
    find "$LOG_DIR" -type f -mtime +30 -delete >> "$LOG" 2>&1 || log "WARN: log cleanup failed"
  fi
fi

log "Quarterly deep clean complete."
