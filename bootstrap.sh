#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting new-Mac bootstrap..."

# --------------------------------------------------
# 1. Install Xcode Command Line Tools (if missing)
# --------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  echo "📦 Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "👉 After installation finishes, re-run this script."
  exit 1
fi

# --------------------------------------------------
# 2. Install Homebrew (if missing)
# --------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "✅ Homebrew ready"

# --------------------------------------------------
# 3. Install chezmoi
# --------------------------------------------------
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "📦 Installing chezmoi..."
  brew install chezmoi
fi

echo "✅ chezmoi ready"

# --------------------------------------------------
# 4. Restore age key (REQUIRED for encrypted secrets)
# --------------------------------------------------
AGE_KEY_PATH="$HOME/.config/chezmoi/age.txt"

if [ ! -f "$AGE_KEY_PATH" ]; then
  echo "🔐 Age key not found."
  echo "Paste your age key below, then press CTRL+D:"
  mkdir -p "$(dirname "$AGE_KEY_PATH")"
  cat > "$AGE_KEY_PATH"
  chmod 600 "$AGE_KEY_PATH"
  echo "✅ Age key restored"
fi

# --------------------------------------------------
# 5. Initialize chezmoi from your repo
# --------------------------------------------------
DOTFILES_REPO="https://github.com/rushabhpasad/dotfiles.git"

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  echo "📥 Cloning dotfiles..."
  chezmoi init --apply "$DOTFILES_REPO"
else
  echo "🔄 Updating existing dotfiles..."
  chezmoi update --apply
fi

echo "✅ Dotfiles applied"

# --------------------------------------------------
# 6. Install Brew packages from Brewfile
# --------------------------------------------------
if [ -f "$HOME/.Brewfile" ]; then
  echo "📦 Installing Brew bundle (this may take a while)..."
  brew bundle --file="$HOME/.Brewfile"
  echo "✅ Brew packages installed"
else
  echo "⚠️  No Brewfile found, skipping package install"
fi

# --------------------------------------------------
# 7. Final message
# --------------------------------------------------
echo ""
echo "🎉 Bootstrap complete!"
echo "👉 Restart terminal or run: exec zsh"
echo "👉 Verify SSH, cloud logins, and secrets mount"

