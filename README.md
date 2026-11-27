# cadre_marketplace

Claude Code plugins for [Cadre](https://colette-cadre.fly.dev), which shows where every milestone stands, on every repo, in deploy order (marketplace name: `cadre`).

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

## Development

```bash
LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb
```

To release a plugin, follow "Release" in [AGENTS.md](AGENTS.md).
