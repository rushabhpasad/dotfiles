---
name: Java Best Practices
description: Java code style and structure guidelines.
globs: ["**/*.java"]
---

# Java Code Standards
- Follow Google Java Style or the existing project conventions.
- Keep methods short and focused — one responsibility each.
- Always use meaningful, camelCase naming.
- Include Javadoc for all public classes and methods.
- Avoid null pointer risks — prefer `Optional` or clear null checks.
- Prefer immutability where practical.
- Use streams and modern APIs instead of legacy loops when appropriate.
- Avoid deep nesting — prefer early returns or guard clauses.
- Group related methods logically, and keep test code separate from main code.
