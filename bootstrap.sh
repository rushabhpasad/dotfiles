#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Elite macOS bootstrap (Rushabh edition)"

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
# 4. Restore age key
# --------------------------------------------------
AGE_KEY="$HOME/.config/chezmoi/age.txt"

if [ ! -f "$AGE_KEY" ]; then
  echo "🔐 Paste AGE key, then CTRL+D:"
  mkdir -p "$(dirname "$AGE_KEY")"
  cat > "$AGE_KEY"
  chmod 600 "$AGE_KEY"
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

# --------------------------------------------------
# 6. Brew bundle
# --------------------------------------------------
if [ -f "$HOME/.Brewfile" ]; then
  echo "📦 Installing Brewfile packages..."
  brew bundle --file="$HOME/.Brewfile"
else
  echo "⚠️  No ~/.Brewfile found, skipping bundle install"
fi

# ==================================================
# macOS UX RESTORE (REAL CUSTOMIZATIONS ONLY)
# ==================================================

echo "🎨 Applying macOS UX defaults..."

# ---------------- Global ----------------

defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
defaults write NSGlobalDomain KeyRepeat -int 5
defaults write NSGlobalDomain InitialKeyRepeat -int 25
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ---------------- Finder ----------------

defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

killall Finder 2>/dev/null || true

# ---------------- Dock ----------------

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock tilesize -int 37

# Hot corners (with modifiers set to none)
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 10
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 1
defaults write com.apple.dock wvous-bl-modifier -int 0

killall Dock 2>/dev/null || true

# ---------------- Trackpad ----------------

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1.5

defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadMomentumScroll -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 2

# ---------------- Accessibility ----------------

defaults write com.apple.Accessibility KeyRepeatEnabled -int 1
defaults write com.apple.Accessibility KeyRepeatInterval -float 0.083333333
defaults write com.apple.Accessibility KeyRepeatDelay -float 0.416666666

# Screen zoom behavior (not forced on)
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess closeViewFlashScreenOnNotificationEnabled -bool true
defaults write com.apple.universalaccess closeViewSplitScreenRatio -float 0.2
defaults write com.apple.universalaccess closeViewZoomedIn -bool false

echo "✅ macOS UX restored"

# --------------------------------------------------
# 7. Dev directories
# --------------------------------------------------
mkdir -p "$HOME/workspace" "$HOME/projects" "$HOME/tmp" "$HOME/.local/bin"

echo ""
echo "🎉 Rushabh’s workstation is ready."
echo "➡️ Restart terminal or run: exec zsh"