#!/usr/bin/env bash
set -euo pipefail

# Prerequisites for chezmoi to run. Everything else (Brewfile, macOS defaults,
# dev dirs) lives in run_*-prefixed scripts invoked by `chezmoi apply`.

LOG="$HOME/bootstrap.log"
LOG_MAX_BYTES=5242880  # 5 MiB

if [[ -f "$LOG" && $(stat -f%z "$LOG" 2>/dev/null || echo 0) -gt $LOG_MAX_BYTES ]]; then
  mv "$LOG" "$LOG.1"
fi

exec > >(tee -a "$LOG") 2>&1

echo ""
echo "=========================================="
echo "🚀 macOS bootstrap"
echo "    started at $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# --------------------------------------------------
# 1. Xcode CLI tools
# --------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  echo "📦 Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "⏳ Waiting for installation to complete..."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
fi

# --------------------------------------------------
# 2. Homebrew
# --------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "✅ Homebrew ready"

# --------------------------------------------------
# 3. chezmoi
# --------------------------------------------------
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "📦 Installing chezmoi..."
  brew install chezmoi
fi

echo "✅ chezmoi ready"

# --------------------------------------------------
# 4. Age key (required to decrypt managed secrets)
# --------------------------------------------------
AGE_KEY="$HOME/.config/chezmoi/age.txt"

if [ ! -f "$AGE_KEY" ]; then
  if [[ ! -t 0 ]]; then
    echo "❌ Cannot read AGE key from non-TTY stdin (piped/redirected execution)." >&2
    echo "   Run as: ./bootstrap.sh   (not via curl | bash)" >&2
    exit 1
  fi

  echo "🔐 Paste AGE key, then CTRL+D:"
  mkdir -p "$(dirname "$AGE_KEY")"
  cat > "$AGE_KEY"
  chmod 600 "$AGE_KEY"

  if ! grep -q '^AGE-SECRET-KEY-' "$AGE_KEY"; then
    echo "❌ Pasted content doesn't look like an age key (missing 'AGE-SECRET-KEY-' prefix)." >&2
    rm -f "$AGE_KEY"
    exit 1
  fi
fi

# --------------------------------------------------
# 5. chezmoi apply — triggers run_once_* / run_onchange_* scripts:
#    - install Brewfile packages (run_onchange, keyed on Brewfile hash)
#    - apply macOS UX defaults (run_once, re-runnable via ~/scripts/apply-macos-defaults.sh)
#    - create dev directories (run_once)
# --------------------------------------------------
DOTFILES_REPO="https://github.com/rushabhpasad/dotfiles.git"

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  echo "📥 Cloning dotfiles..."
  chezmoi init --apply "$DOTFILES_REPO"
else
  echo "🔄 Updating existing dotfiles..."
  if ! chezmoi update --apply; then
    echo "⚠️  chezmoi update failed (likely local uncommitted changes, merge conflict, or network issue)." >&2
    echo "   Continuing with existing source state. Resolve manually and re-run if needed." >&2
  fi
fi

echo ""
echo "🎉 Bootstrap complete."
echo "➡️  Restart terminal or run: exec zsh"
