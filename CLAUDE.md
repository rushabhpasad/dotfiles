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

## Backup Workflow

Backups are **manual** (run when you sit down at the machine). The previous LaunchAgent was removed because non-interactive runs can't reliably handle GPG-signed commits without a TTY for pinentry.

Run `~/scripts/chezmoi-auto-commit.sh` to:
1. Regenerate `~/.Brewfile` from installed packages
2. `git pull --rebase --autostash` to sync with remote (prevents silent push failures)
3. Run `chezmoi diff` → `chezmoi re-add` if changes detected
4. Refuse to commit if either of two scans flags the staged changes:
   - **Filename**: matches `.pem`, `.key`, `.p12`, `.jks`, `.keystore`, `.env`, `.kdbx`, `age.txt`, `credentials/`, `id_rsa`/`id_ed25519`/`id_ecdsa`/`id_dsa`, `.aws/`, `.gnupg/`, `.netrc` (`.pub` files exempted)
   - **Content**: `gitleaks git --staged` finds a secret pattern in the diff
5. Commit and push with `auto: periodic dotfile backup (timestamp)`. Script exits non-zero (and skips the "Backup complete." log line) if commit or push fails.

Log: `~/chezmoi-auto-commit.log` (rotates to `.1` at 5 MiB).

## Maintenance Scripts

`~/scripts/brew-maintenance.sh` and `~/scripts/quarterly-deep-clean.sh` are also manual. Both share an `shlock`-based lock at `~/.cache/brew-maintenance.lock` so they cannot run concurrent brew operations. Logs rotate at 5 MiB.

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

All commits in this repo are GPG-signed (`commit.gpgSign = true` in `dot_gitconfig`). The active signing key varies by profile (personal vs. Testlify via the conditional `includeIf` in `dot_gitconfig`) — check `git config user.signingKey` in the relevant working tree. If signing fails, confirm `gpg-agent` is running.
