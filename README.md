# cadre_marketplace

Claude Code plugins (marketplace name: `cadre`): cadre runs [Cadre](https://colette-cadre.fly.dev), which shows where every milestone stands, on every repo, in deploy order; engineering-review reviews code, with `security-audit` as its security layer.

## Use it

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin marketplace add djeusette/cadre_marketplace
/plugin install cadre@cadre
```

Skip the first line when `claude-plugins-official` is already added. cadre's skills need superpowers 7.0 or later.

Or commit them to a repo's `.claude/settings.json` so the whole team gets them automatically.

## Plugins

- **cadre** — runs Cadre from Claude Code: it starts milestones and links their pull requests, connects repos to Fly, Vercel or the app stores, deploys them and writes Skills tables. [`cadre:brainstorming`](plugins/cadre/skills/brainstorming/SKILL.md) brainstorms a feature into a Cadre project; [`cadre:writing-plans`](plugins/cadre/skills/writing-plans/SKILL.md) plans a milestone's pull request; [`cadre:pr-description`](plugins/cadre/skills/pr-description/SKILL.md) sets the standard for PR descriptions. It installs the `cadre` CLI and signs you in; cadre installs `superpowers` from `claude-plugins-official` with it. [The skill](plugins/cadre/skills/cadre/SKILL.md).
- **engineering-review** — language-agnostic engineering principles, `break-check`, which proves each branch a change adds or changes has a test, and `review-companion`, which reviews a change in any language and writes a report for the human reviewer, who decides. The review loads the skills the repository's `AGENTS.md` Skills table lists, runs the repository's tests and checks, and runs Cloudflare's `security-audit` skill as its security layer. Installing it installs `security-audit`. Start a review with `/engineering-review:review-companion`.
- **security-audit** — Cloudflare's [security-audit skill](https://github.com/cloudflare/security-audit-skill), pinned to one commit.

## Development

To run the checks, follow "Checks" in [AGENTS.md](AGENTS.md). To release a plugin, follow "Release" in [AGENTS.md](AGENTS.md).
