#!/usr/bin/env bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

CHEZMOI_SRC="$HOME/.local/share/chezmoi"
BREWFILE="$HOME/.Brewfile"
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

log "Starting chezmoi auto-backup..."

# --------------------------------------------------
# 1. Refresh Brewfile (only if brew exists)
# --------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  log "Updating Brewfile..."

  TMP_BREWFILE="$(mktemp)"
  brew bundle dump --force --file="$TMP_BREWFILE" >/dev/null 2>&1 || true

  if [[ ! -f "$BREWFILE" ]] || ! cmp -s "$TMP_BREWFILE" "$BREWFILE"; then
    mv "$TMP_BREWFILE" "$BREWFILE"
    log "Brewfile updated."
  else
    rm "$TMP_BREWFILE"
    log "Brewfile unchanged."
  fi
fi

# --------------------------------------------------
# 2. Go to chezmoi source
# --------------------------------------------------
cd "$CHEZMOI_SRC"

# --------------------------------------------------
# 3. Detect dotfile changes
# --------------------------------------------------
if ! chezmoi diff --quiet; then
  log "Changes detected. Re-adding tracked files..."

  run_cmd chezmoi re-add || true

  # --------------------------------------------------
  # 4. Safety: block committing obvious secrets
  # --------------------------------------------------
  if git diff --name-only | grep -Ei '\.(pem|key|p12|keystore|env)$|age\.txt|credentials' >/dev/null 2>&1; then
    log "⚠️ Potential secret detected. Skipping commit."
    exit 0
  fi

  # --------------------------------------------------
  # 5. Commit & push (only if staged changes exist)
  # --------------------------------------------------
  if ! git diff --cached --quiet; then
    COMMIT_MSG="auto: periodic dotfile backup ($(timestamp))"

    run_cmd git add .
    run_cmd git commit -m "$COMMIT_MSG" || true
    run_cmd git push || true

    log "Backup complete."
  else
    log "No staged changes after re-add."
  fi
else
  log "No dotfile changes."
fi