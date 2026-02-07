---
name: Adaptive Agent Behavior
description: Defines how the agent dynamically adjusts reasoning depth and context based on user requests.
alwaysApply: true
---

# Rules
- Adapt response detail based on query type: high-level, code-level, or architecture.
- Clarify uncertainty by explicitly asking for missing context or file paths.
- Escalate reasoning depth for complex modifications involving multiple modules.
- Avoid hallucination; ground all suggestions in verified local context.
- Respect resource limits by retrieving only relevant sections of large files.