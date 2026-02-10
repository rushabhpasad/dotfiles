#!/usr/bin/env bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

LOG="$HOME/$(basename "$0" .sh).log"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  local msg="[$(timestamp)] $*"
  echo "$msg" >> "$LOG"

  # Print to terminal if interactive
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
# Prevent running on battery (safety)
# --------------------------------------------------
if pmset -g batt | grep -q "Battery Power"; then
  log "On battery. Skipping deep clean."
  exit 0
fi

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
# Brew deep cleanup
# --------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  log "Brew deep cleanup..."
  run_cmd brew cleanup -s || true

  BREW_CACHE="$HOME/Library/Caches/Homebrew"
  if [[ -d "$BREW_CACHE" ]]; then
    log "Clearing Homebrew cache..."
    rm -rf -- "$BREW_CACHE"
    mkdir -p "$BREW_CACHE"
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