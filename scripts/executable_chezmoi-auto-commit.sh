#!/bin/bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

CHEZMOI_SRC="$HOME/.local/share/chezmoi"
BREWFILE="$HOME/.Brewfile"
LOG="$HOME/$(basename "$0" .sh).log"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

log() {
  local msg="[$(timestamp)] $*"
  echo "$msg" >> "$LOG"
  [[ -t 1 ]] && echo "$msg"
}

run_cmd() {
  if [[ -t 1 ]]; then
    "$@" 2>&1 | tee -a "$LOG" || log "WARN: command failed → $*"
  else
    "$@" >> "$LOG" 2>&1 || log "WARN: command failed → $*"
  fi
}

echo "" >> "$LOG"
log "========== Starting chezmoi auto-backup =========="

# --------------------------------------------------
# 1. Refresh Brewfile
# --------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  log "Refreshing Brewfile..."

  TMP_BREWFILE="$(mktemp)"
  run_cmd brew bundle dump --force --file="$TMP_BREWFILE"

  if [[ ! -f "$BREWFILE" ]] || ! cmp -s "$TMP_BREWFILE" "$BREWFILE"; then
    mv "$TMP_BREWFILE" "$BREWFILE"
    log "Brewfile updated."
  else
    rm "$TMP_BREWFILE"
    log "Brewfile unchanged."
  fi
else
  log "Brew not installed. Skipping Brewfile."
fi

# --------------------------------------------------
# 2. Validate chezmoi source repo
# --------------------------------------------------
if [[ ! -d "$CHEZMOI_SRC/.git" ]]; then
  log "ERROR: chezmoi repo missing."
  exit 1
fi

cd "$CHEZMOI_SRC"

# Ensure on main branch (optional but smart)
if ! git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
  log "ERROR: git repo unhealthy."
  exit 1
fi

# --------------------------------------------------
# 3. Detect dotfile changes
# --------------------------------------------------

DIFF_OUTPUT="$(chezmoi diff)"
if [[ -n "$DIFF_OUTPUT" ]]; then
  log "Changes detected. Re-adding tracked files..."
  log "$DIFF_OUTPUT"
  
  run_cmd chezmoi re-add

  # Stage updated tracked files
  run_cmd git add -u

  # --------------------------------------------------
  # Secret detection (check staged changes only)
  # --------------------------------------------------
  if git diff --cached --name-only \
      | grep -Ei '\.(pem|key|p12|keystore|env)$|age\.txt|credentials' \
      >/dev/null 2>&1; then
    log "⚠️ Potential secret detected in staged files. Skipping commit."
    git reset
    exit 0
  fi

  # --------------------------------------------------
  # Commit only if staged changes exist
  # --------------------------------------------------
  if ! git diff --cached --quiet; then
    COMMIT_MSG="auto: periodic dotfile backup ($(timestamp))"

    run_cmd git commit -m "$COMMIT_MSG"
    run_cmd git push

    log "Backup complete."
  else
    log "No changes after staging."
  fi
else
  log "No dotfile changes."
fi

log "========== Backup run finished =========="