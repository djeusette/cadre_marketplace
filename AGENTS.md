# cadre_marketplace

## Checks

Run `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`. Without `LANG` it dies with "invalid byte sequence in US-ASCII".

`plugin_test.rb` pins the skill's exact wording: change the test first, watch it go red, then the text.

## Release

Bump the version in `plugins/cadre/.claude-plugin/plugin.json`, in `.claude-plugin/marketplace.json` and in `test_marketplace_lists_cadre_last_at_the_plugin_version`.

## Skills

| Skill | When | Install |
| --- | --- | --- |
| `mattpocock-skills:writing-for-agents` | skills, agents, AGENTS.md, CLAUDE.md or any other agent instructions | `claude plugin install mattpocock-skills@claude-plugins-official` |
| `superpowers:writing-skills` | writing or editing a skill | `claude plugin install superpowers@claude-plugins-official` |

Load each skill whose When fits the work before starting it, and name them in every subagent brief. Where `superpowers:writing-skills` and `mattpocock-skills:writing-for-agents` disagree, `mattpocock-skills:writing-for-agents` wins.

The cadre skill's description starts with `Cadre`.

For a row naming a plugin skill, enable its plugin under `enabledPlugins` in `.claude/settings.json`.
