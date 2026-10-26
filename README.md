# cadre_marketplace

Claude Code plugins for [Cadre](https://colette-cadre.fly.dev), which shows where every milestone stands, on every repo, in deploy order (marketplace name: `cadre`).

## Use it

The `cadre` plugin needs the `colette` plugin from colette-club/colette-marketplace, so add both marketplaces:

```
/plugin marketplace add colette-club/colette-marketplace
/plugin marketplace add djeusette/cadre_marketplace
/plugin install cadre@cadre
```

Or commit them to a repo's `.claude/settings.json` so the whole team gets them automatically.

## Plugins

- **cadre** — registers a feature with Cadre from a colette spec: one milestone per
  increment, each with its repos in deploy order. It installs the `cadre` CLI from its
  GitHub release (needs `gh`), signs the person in through the browser, and reports the
  project's URL. It needs the `colette` plugin.

## Development

```bash
LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb
```

Release a plugin by bumping its version in both `plugins/<name>/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
