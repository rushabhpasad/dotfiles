#!/usr/bin/env bash
set -euo pipefail

# Idempotent — `defaults write` overwrites the same value silently.
# Re-run any time to reassert preferences after macOS upgrades.

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

defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess closeViewFlashScreenOnNotificationEnabled -bool true
defaults write com.apple.universalaccess closeViewSplitScreenRatio -float 0.2
defaults write com.apple.universalaccess closeViewZoomedIn -bool false

echo "✅ macOS UX defaults applied."
