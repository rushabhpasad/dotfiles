---
name: Code Search & Retrieval Strategy
description: Outlines how the agent retrieves and uses context from the local codebase before reasoning or code generation.
alwaysApply: true
---

# Rules
- Perform semantic searches to locate related functions, patterns, or definitions.
- Retrieve 2–3 most relevant code snippets or documentation references before answering.
- Always prefer local examples from the project over external or generic examples.
- Summarize the context retrieved before applying it in reasoning or code generation.
- Continuously learn from recently edited files during an active session.