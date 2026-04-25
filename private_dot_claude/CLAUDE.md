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

## Custom Skills
@RTK.md
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
