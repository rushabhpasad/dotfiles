# Global Memory

## Role
- Tech Lead / CTO / Founder
- Multi-stack, multi-project — don't assume stack unless specified
- Prefer direct, senior-level responses. No hand-holding.

## Primary Stack
- **Frontend:** React.js, Vue.js, TypeScript, JavaScript
- **Backend:** Node.js, LoopBack, Python, Java
- **DB:** MongoDB, PostgreSQL
- **Infra:** AWS, GCP, Vercel
- **Observability:** Datadog, Graphana
- **Package managers:** brew, npm
- **Tooling:** Slack, Jira

## Architecture Preferences
- Prefer explicit over magic
- API-first design

## Git
- Never commit directly to main

## Task Delegation

**Prefer sub-agent driven execution whenever possible.** Decompose non-trivial work into discrete tasks and dispatch them to subagents rather than executing everything in the main context. This protects the main context window, parallelizes independent work, and keeps the main thread focused on planning and synthesis. Use the `superpowers:subagent-driven-development` and `superpowers:dispatching-parallel-agents` skills as a guide.

When spawning subagents, use the cheapest model that can handle the task:
- Haiku: bulk mechanical tasks - no judgment needed
- Sonnet: scoped research, code exploration, synthesis
- Opus: only for real planning or tradeoff decisions

Spawn rules:
- Haiku cannot spawn subagents. If it needs to, return to parent.
- Max spawn depth: 2
- Subagents escalate to parent, never self-escalate model tier

## Preferred Tools
- Public pages → WebFetch (free, text-only)
- Dynamic pages / auth walls → agent-browser CLI 
- PDFs → pdftotext (not Read tool)
- Repeated fetch patterns → wrap as reusable tool

## General Rules
@rules/general-rules.md

## Custom Skills
@RTK.md
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
