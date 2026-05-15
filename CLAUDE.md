# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Dotfiles managed by **chezmoi** — the source of truth for a reproducible macOS workstation. Changes here are applied to `~` via chezmoi, not used directly.

## Key Commands

```bash
# Apply changes from this repo to the home directory
chezmoi apply

# Preview what would change before applying
chezmoi diff

# Pull in changes from home → chezmoi source (re-add tracked files)
chezmoi re-add

# Add a new file to be tracked
chezmoi add ~/.some-config-file

# Edit a managed file (opens in $EDITOR, applies on save)
chezmoi edit ~/.zshrc

# Fresh machine bootstrap (downloads and runs bootstrap.sh)
chezmoi init --apply https://github.com/rushabhpasad/dotfiles.git

# Rebuild Brewfile from current installed packages
brew bundle dump --force --file=~/.Brewfile
```

## Chezmoi File Naming Conventions

Chezmoi uses prefixes/suffixes to encode how files are deployed:

| Source name | Deployed as |
|---|---|
| `dot_zshrc` | `~/.zshrc` |
| `private_dot_ssh/` | `~/.ssh/` (mode 0700) |
| `private_Library/` | `~/Library/` (mode 0700) |
| `encrypted_private_*.age` | Decrypted via `~/.config/chezmoi/age.txt` |
| `executable_*.sh` | Deployed as executable script |
| `empty_dot_stCommitMsg` | Deployed as an empty file |

## Architecture: Three Security Layers

1. **This repo** — shell configs, git config, Brewfile, Starship, tool configs, and encrypted secrets (`*.age` files). Safe for Git.
2. **`~/secrets/`** — infra PEM keys, keystores, cloud creds. Never in Git.
3. **`~/.config/chezmoi/age.txt`** — the age private key that decrypts all `*.age` files. Never in Git. Loss = permanent data loss.

## Automated Backup

A LaunchAgent (`private_Library/LaunchAgents/com.rpasad.chezmoi-backup.plist`) runs `scripts/executable_chezmoi-auto-commit.sh` every 6 hours. It:
1. Regenerates `~/.Brewfile` from installed packages
2. Runs `chezmoi diff` → `chezmoi re-add` if changes detected
3. Commits and pushes with `auto: periodic dotfile backup (timestamp)` message
4. Aborts if staged files match secret patterns (`.pem`, `.key`, `.age`, `credentials`)

Log: `~/chezmoi-auto.log`

## Adding New Secrets

All secrets must be age-encrypted before committing:

```bash
# Encrypt a file in-place
chezmoi encrypt ~/.ssh/id_rsa > ~/.local/share/chezmoi/private_dot_ssh/encrypted_private_id_rsa.age

# Or let chezmoi handle it — edit .chezmoiencrypt or use chezmoi add --encrypt
chezmoi add --encrypt ~/.some-secret-file
```

## Shell Environment

`.zshrc` sources these in order:
- `~/.profile` (via `.zprofile` for login shells)
- `~/.local-terminal-settings/.custom-alias`
- `~/.local-terminal-settings/.zsh-functions`

Runtime managers active: **fnm** (Node), **pyenv** (Python), **sheldon** (zsh plugin manager), **conda** (miniconda), **Starship** (prompt).

## Git Signing

All commits in this repo are GPG-signed (`commit.gpgSign = true` in `dot_gitconfig`). The signing key is `B3E5F0F39452FAA21E8CADBB4199574005EEA5D7`. If GPG signing fails, check that `gpg-agent` is running.
