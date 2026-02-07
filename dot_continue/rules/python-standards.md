---
name: Python Standards
description: Rules for writing and refactoring Python code.
globs: ["**/*.py"]
---

# Python Coding Rules
- Follow PEP8 style guidelines.
- Use type hints for all functions and method signatures.
- Include docstrings (triple-quoted) describing purpose, parameters, and returns.
- Avoid using wildcard imports (`from x import *`).
- Prefer list/dict comprehensions over manual loops where clear.
- Use f-strings for string formatting.
- Avoid mutable default arguments.
- Always handle potential exceptions with meaningful error messages.
- Use `logging` instead of `print` for production diagnostics.
