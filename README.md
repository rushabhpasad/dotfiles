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

## 1. Download and run bootstrap script

```bash
curl -fsSL https://raw.githubusercontent.com/rushabhpasad/dotfiles/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

