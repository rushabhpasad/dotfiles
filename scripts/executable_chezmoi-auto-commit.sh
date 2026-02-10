#!/usr/bin/env bash
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

LOG="$HOME/chezmoi-auto.log"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
CHEZMOI_SRC="$HOME/.local/share/chezmoi"
BREWFILE="$HOME/.Brewfile"

echo "[$DATE] Starting chezmoi auto-backup..." >> "$LOG"

# --------------------------------------------------
# 1. Refresh Brewfile (only if brew exists)
# --------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  echo "[$DATE] Updating Brewfile..." >> "$LOG"

  # Dump current brew state to a temp file
  TMP_BREWFILE="$(mktemp)"
  brew bundle dump --force --file="$TMP_BREWFILE" >/dev/null 2>&1 || true

  # Replace only if changed (avoids useless commits)
  if ! cmp -s "$TMP_BREWFILE" "$BREWFILE"; then
    mv "$TMP_BREWFILE" "$BREWFILE"
    echo "[$DATE] Brewfile updated." >> "$LOG"
  else
    rm "$TMP_BREWFILE"
    echo "[$DATE] Brewfile unchanged." >> "$LOG"
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
  echo "[$DATE] Changes detected. Re-adding tracked files..." >> "$LOG"

  # Update only tracked files (safe)
  chezmoi re-add

  # --------------------------------------------------
  # 4. Safety: block committing obvious secrets
  # --------------------------------------------------
  if git diff --name-only | grep -E '\.pem$|\.key$|age\.txt' >/dev/null 2>&1; then
    echo "[$DATE] ⚠️ Potential secret detected. Skipping commit." >> "$LOG"
    exit 0
  fi

  # --------------------------------------------------
  # 5. Commit & push
  # --------------------------------------------------
  git add .
  git commit -m "auto: periodic dotfile backup ($DATE)" >> "$LOG" 2>&1 || true
  git push >> "$LOG" 2>&1 || true

  echo "[$DATE] Backup complete." >> "$LOG"
else
  echo "[$DATE] No dotfile changes." >> "$LOG"
fi