---
name: Codebase Awareness
description: Defines how the agent interprets and aligns with the structure, technology, and conventions of the active workspace.
alwaysApply: true
---

# Rules
- Detect the active workspace root and identify project type (e.g., Node.js, Java, Python, Swift).
- Infer frameworks and libraries from directory patterns (e.g., /src/main/java, /lib, /app).
- Use existing code conventions, file naming, and structure when providing code suggestions.
- Reference existing modules, functions, and classes instead of introducing redundant ones.
- Use project metadata (e.g., README.md, setup.py, package.json, pom.xml) to determine project purpose.
- Cross-check imports and dependencies against local manifests (e.g., requirements.txt, build.gradle).
- Maintain awareness of multiple services or packages and their interdependencies.