# cadre_marketplace

Rules for any agent working in this repo.

## Skills

| Skill | When | Install |
| --- | --- | --- |
| `mattpocock-skills:writing-for-agents` | skills, agents, AGENTS.md, CLAUDE.md or any other agent instructions | `claude plugin install mattpocock-skills@claude-plugins-official` |
| `superpowers:writing-skills` | writing or editing a skill | `claude plugin install superpowers@claude-plugins-official` |

Load each skill whose When fits the work before starting it, and name them in every subagent brief.

A plugin skill's plugin is enabled in `.claude/settings.json`.
