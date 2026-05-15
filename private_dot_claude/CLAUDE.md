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

## Code Preferences
- Functional components, hooks over class components (React)
- async/await over .then()
- Named exports over default exports
- Early returns over nested conditionals
- No comments unless logic is non-obvious
- TypeScript strict mode by default

## Architecture Preferences
- 12-factor app principles
- Prefer explicit over magic
- Design for observability (structured logs, meaningful errors)
- API-first design

## Git
- Conventional commits: feat/fix/chore/refactor/perf
- Never commit directly to main
- PRs should be small and focused

## Task Delegation

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

## Docs
When making changes to codebases -
- Update README.md when the consumer-facing understanding of the project changes. Do not overload README.md with operational rules for agents.
- Update AGENTS.md / CLAUDE.md when the AI/developer operational behavior changes. AGENTS.md is preferred over CLAUDE.md.
- Update ARCHITECTURE.md when System design and decisions are changed.
- Update /docs/* for deeper understanding of modules/components/systems/projects.

If a file is not present, propose to create the file.

## Custom Skills
@RTK.md
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
