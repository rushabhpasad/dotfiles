#!/bin/bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

CHEZMOI_SRC="$HOME/.local/share/chezmoi"
BREWFILE="$HOME/.Brewfile"
LOG="$HOME/$(basename "$0" .sh).log"
LOG_MAX_BYTES=5242880  # 5 MiB

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

log() {
  local msg
  msg="[$(timestamp)] $*"

  if [[ -f "$LOG" && $(stat -f%z "$LOG" 2>/dev/null || echo 0) -gt $LOG_MAX_BYTES ]]; then
    mv "$LOG" "$LOG.1"
  fi

  echo "$msg" >> "$LOG"
  [[ -t 1 ]] && echo "$msg"
}

run_cmd() {
  local rc
  if [[ -t 1 ]]; then
    "$@" 2>&1 | tee -a "$LOG"
    rc=${PIPESTATUS[0]}
  else
    "$@" >> "$LOG" 2>&1
    rc=$?
  fi
  if [[ $rc -ne 0 ]]; then
    log "WARN: command failed (rc=$rc) → $*"
  fi
  return "$rc"
}

echo "" >> "$LOG"
log "========== Starting chezmoi auto-backup =========="

# --------------------------------------------------
# 1. Refresh Brewfile
# --------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  log "Refreshing Brewfile..."

  TMP_BREWFILE="$(mktemp)"
  run_cmd brew bundle dump --force --file="$TMP_BREWFILE" || true

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

if ! git rev-parse --abbrev-ref HEAD >/dev/null 2>&1; then
  log "ERROR: git repo unhealthy."
  exit 1
fi

# --------------------------------------------------
# 3. Sync with remote first (prevents silent non-fast-forward push failures)
# --------------------------------------------------
if ! run_cmd git pull --rebase --autostash; then
  log "ERROR: git pull failed. Aborting backup."
  exit 1
fi

# --------------------------------------------------
# 4. Detect dotfile changes
# --------------------------------------------------
DIFF_OUTPUT="$(chezmoi diff || true)"
if [[ -n "$DIFF_OUTPUT" ]]; then
  log "Changes detected. Re-adding tracked files..."
  log "$DIFF_OUTPUT"

  run_cmd chezmoi re-add || true
  run_cmd git add -u || true

  # --------------------------------------------------
  # Secret detection (filename-based; extended)
  # --------------------------------------------------
  STAGED_FILES="$(git diff --cached --name-only || true)"
  if [[ -n "$STAGED_FILES" ]] && printf '%s\n' "$STAGED_FILES" \
      | grep -Eiv '\.pub$' \
      | grep -Ei '\.(pem|key|p12|jks|keystore|env|kdbx)$|(^|/)age\.txt$|(^|/)credentials($|/)|(^|/)id_(rsa|ed25519|ecdsa|dsa)($|\.)|(^|/)\.aws/|(^|/)\.gnupg/|(^|/)\.netrc$' \
      >/dev/null 2>&1; then
    log "⚠️ Potential secret detected in staged filenames. Skipping commit."
    log "$STAGED_FILES"
    git reset
    exit 0
  fi

  # --------------------------------------------------
  # Secret detection (content-based via gitleaks)
  # --------------------------------------------------
  if command -v gitleaks >/dev/null 2>&1 && [[ -n "$STAGED_FILES" ]]; then
    if ! gitleaks git --staged --no-banner --redact "$CHEZMOI_SRC" >> "$LOG" 2>&1; then
      log "⚠️ gitleaks flagged staged content. Skipping commit. See $LOG for details."
      git reset
      exit 0
    fi
  fi

  # --------------------------------------------------
  # Commit + push (only if staged changes exist)
  # --------------------------------------------------
  if ! git diff --cached --quiet; then
    COMMIT_MSG="auto: periodic dotfile backup ($(timestamp))"

    if run_cmd git commit -m "$COMMIT_MSG" && run_cmd git push; then
      log "Backup complete."
    else
      log "ERROR: commit or push failed."
      exit 1
    fi
  else
    log "No changes after staging."
  fi
else
  log "No dotfile changes."
fi

log "========== Backup run finished =========="
