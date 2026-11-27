# cadre_marketplace

## Checks

Run each before a commit:

- `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`. Without `LANG` it dies with "invalid byte sequence in US-ASCII".
- `python3 -m unittest discover -s plugins/engineering-review/scripts -p 'test_*.py'`
- `python3 plugins/engineering-review/scripts/check_plugin.py plugin plugins/engineering-review`
- `ruby test/check_version_bumps_test.rb`

`plugin_test.rb` and `test_check_plugin.py` pin their plugin's exact wording: change the test first, watch it go red, then the text.

## Release

Every merge to `main` is a release: a pull request that changes `plugins/<name>/` bumps that plugin's version.

- cadre: in `plugins/cadre/.claude-plugin/plugin.json`, in `.claude-plugin/marketplace.json` and in `test_marketplace_lists_cadre_at_the_plugin_version`.
- engineering-review: in `plugins/engineering-review/.claude-plugin/plugin.json` and in `.claude-plugin/marketplace.json`.

## Skills

| Skill | When | Install |
| --- | --- | --- |
| `mattpocock-skills:writing-for-agents` | skills, agents, AGENTS.md, CLAUDE.md or any other agent instructions | `claude plugin install mattpocock-skills@claude-plugins-official` |
| `superpowers:writing-skills` | writing or editing a skill | `claude plugin install superpowers@claude-plugins-official` |

Load each skill whose When fits the work before starting it, and name them in every subagent brief. Where `superpowers:writing-skills` and `mattpocock-skills:writing-for-agents` disagree, `mattpocock-skills:writing-for-agents` wins.

The cadre skill's description starts with `Cadre`.

For a row naming a plugin skill, enable its plugin under `enabledPlugins` in `.claude/settings.json`.
