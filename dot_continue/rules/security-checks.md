---
name: Security Checks
description: Security-focused review and code generation rules.
alwaysApply: true
---

# Security and Safety Rules
- Never include hardcoded credentials, tokens, or secrets.
- Sanitize all external input (files, network data, user input).
- Escape output for HTML, SQL, or command-line contexts.
- Validate all user inputs and file paths.
- Avoid dangerous functions (e.g., `eval`, `exec`, `subprocess` with user data).
- Use parameterized queries for database access.
- Use environment variables or secret managers for sensitive data.
- Warn user if sensitive data is exposed or logged.
- When fixing or suggesting code, always maintain least-privilege access principles.
