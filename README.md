# cadre_marketplace

Claude Code plugins for [Cadre](https://colette-cadre.fly.dev), which shows where every milestone stands, on every repo, in deploy order (marketplace name: `cadre`).

## Use it

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin marketplace add djeusette/cadre_marketplace
/plugin install cadre@cadre
```

Skip the first line when `claude-plugins-official` is already added: cadre needs it for `superpowers`, and without it cadre fails to load.

Or commit them to a repo's `.claude/settings.json` so the whole team gets them automatically.

## Plugins

- **cadre** — registers a feature with Cadre. Asked to "create a cadre project", it
  brainstorms the feature with the person through `superpowers:brainstorming`, into an end
  goal and milestones, each the smallest step that ships one feature and deploys on its own. It
  commits that feature spec, or builds from one the person names, then registers one
  milestone per increment, each with its repos in deploy order, its own spec and a page in
  the project's Claude Design canvas. Asked to "update the spec of <project>/<n>", it pulls
  the spec with `cadre spec pull`, edits it with the person, and pushes it back with
  `cadre spec push --base`, so an edit never replaces a newer one. Asked to "start milestone <project>/<n>"
  in one of the milestone's repos, it commits a copy of the milestone's spec there as a record, plans that
  repo's part through `superpowers:writing-plans`, and opens one pull request with a `Cadre: <project>/<n>`
  line, which links it to the milestone; a pull request without the line is linked with `cadre pr link`.
  It installs the `cadre` CLI from its
  GitHub release (needs `gh`) and updates it with `cadre upgrade`, signs the person in through the browser to the Cadre URL they give, and reports the
  project's URL. Installing cadre installs `superpowers` from `claude-plugins-official` with it.

## Development

```bash
LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb
```

Release a plugin by bumping its version in both `plugins/<name>/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
