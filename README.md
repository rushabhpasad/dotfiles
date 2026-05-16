# Dotfiles – Reproducible macOS Workstation

This repository contains the configuration required to recreate my full macOS
development environment using **chezmoi**, **Homebrew**, and **age-encrypted secrets**.

Goal:

> One command → brand-new Mac becomes a fully working dev machine.

---

# Architecture Overview

The setup is intentionally split into **three security layers**:

## 1. Public / Version-controlled (this repo)

Safe to store in Git:

- Shell configuration (`.zshrc`, `.bashrc`, etc.)
- Git configuration
- Starship prompt
- Tool configs
- Brewfile (packages & apps)
- Encrypted secrets (`*.age`)
- Public SSH keys

---

## 2. Local Secrets Vault (`~/secrets`)

**Never stored in Git.**

Contains:

- Infrastructure PEM keys  
- Android keystores  
- Cloud credentials (optional)  
- Backup of GPG private keys (optional)  
- Backup of `age` master key  

---

## 3. Age Encryption Key

File:
```
~/.config/chezmoi/age.txt
```
This key decrypts **all encrypted secrets**.

### Critical Rules

- **Never commit this file**
- Store backups in:
  - Password manager
  - Encrypted offline/cloud backup

Loss = permanent data loss.  
Leak = total secret compromise.

---

# Fresh macOS Bootstrap

## Prerequisites

Before running `bootstrap.sh` on a brand-new machine, stage the following manually — the script does **not** restore them for you:

| Item | Why | How |
|---|---|---|
| **Age private key** (`AGE-SECRET-KEY-...`) | Required to decrypt every `*.age` file deployed by chezmoi (SSH keys, encrypted dotfiles, etc.). The script pauses and prompts you to paste it. | Retrieve from your password manager or encrypted offline backup. Have it on the clipboard before running bootstrap. |
| **GPG private key** (`B3E5F0F3...`) | Required for signed commits in the chezmoi source repo (`commit.gpgSign = true`). Without it, every `git commit` against `~/.local/share/chezmoi` fails. | Restore via `gpg --import < path/to/private.key` **after** bootstrap finishes (or import from `~/secrets/` once that vault is in place). |
| **`~/secrets/` vault** | Holds infra PEM keys, Android keystores, cloud creds, and key backups. Never committed to Git. | Copy from your previous machine (encrypted USB, scp, restic, etc.) **before or after** bootstrap. Not used by the script directly, but referenced by other tools you'll run later. |
| **GitHub access** | Cloning `https://github.com/rushabhpasad/dotfiles.git` works without auth (public repo). | No action needed. |

> ⚠️ **Never** pipe `bootstrap.sh` via `curl | bash`. The age-key paste step reads from stdin, and piping would feed the script body into your key file. The script now refuses non-TTY stdin, but the safer pattern is always: download → review → execute.

## 1. Download and run bootstrap script

```bash
curl -fsSL https://raw.githubusercontent.com/rushabhpasad/dotfiles/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh
```

## What it does

1. Installs Xcode Command Line Tools (waits for the install dialog to complete).
2. Installs Homebrew (Apple Silicon path: `/opt/homebrew`).
3. Installs chezmoi.
4. Prompts for and saves the age key to `~/.config/chezmoi/age.txt` (TTY only; validates the `AGE-SECRET-KEY-` prefix).
5. Runs `chezmoi init --apply` (or `chezmoi update --apply` on re-runs; failures are flagged but non-fatal).
6. Installs everything in `~/.Brewfile` via `brew bundle`.
7. Applies macOS UX defaults (Finder, Dock, Trackpad, Accessibility) — **gated by a sentinel** at `~/.config/rpasad/bootstrap-defaults.done`, so re-runs skip this section.
8. Creates `~/workspace`, `~/projects`, `~/tmp`, `~/.local/bin`.

Logs go to `~/bootstrap.log` (rotates to `.1` at 5 MiB).

## Re-applying macOS defaults

After the first successful run, the defaults block is skipped to preserve any manual tweaks you've made since. To force re-application (e.g., after editing `bootstrap.sh`):

```bash
FORCE_DEFAULTS=1 ./bootstrap.sh
```

Or delete the sentinel and run normally:

```bash
rm ~/.config/rpasad/bootstrap-defaults.done
./bootstrap.sh
```

## After bootstrap

- Import the GPG private key if you haven't yet: `gpg --import < path/to/private.key`
- Verify chezmoi state: `chezmoi diff` should be empty
- Verify brew leaves match expectations: `brew leaves | diff - <(grep '^brew ' ~/.Brewfile | sed 's/brew "\([^"]*\)".*/\1/')`
- Restart your terminal or run `exec zsh`
