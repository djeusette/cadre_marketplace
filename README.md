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
  milestone per increment, each with its repos in deploy order (`repo/app` for a repo with several apps), its own spec and a link straight to its page in
  the project's Claude Design canvas. Asked to "update the spec of <project>/<n>", it pulls
  the spec with `cadre spec pull`, edits it with the person, and pushes it back with
  `cadre spec push --base`, so an edit never replaces a newer one. Asked to "start milestone <project>/<n>"
  in one of the milestone's repos, it commits a copy of the milestone's spec there as a record, plans that
  repo's part through `superpowers:writing-plans`, and opens one pull request with a `Cadre: <project>/<n>`
  line, which links it to the milestone, and names the app after it (`Cadre: <project>/<n> <app>`) when it is for one app of several; a pull request without the line is linked with `cadre pr link`, with `--app` for an app.
  When a change needs something before it ships, such as a new env var, another repo deployed first or a manual step,
  the pull request lists it under `## Before deploying`, one `- [ ]` item each, for the person to tick in GitHub, or for the skill to tick once told the item is done.
  The specs and plans it writes say they are tracked in Cadre, so whoever implements them uses the skill.
  Asked to "connect <repo> to its Fly app", it sets the repo's deploy target with `cadre repo set`,
  asking for a status URL so Cadre can tell when the app is live (a Vercel app takes its production domain when the person has none and it answers), and, once the person agrees,
  connects the Fly org that runs it with `cadre fly org add`, piping a
  read-only token from `fly tokens create` so the token is never shown. Asked to connect a Vercel repo, it sets one target per app with `cadre repo set --vercel-project`, asking for each app's status URL too, and has the person add the team's token with `cadre vercel team add` in their own terminal: Claude Code never handles a Vercel token. A repo can have several apps, on Fly or Vercel, each with a name: when the person names another Fly app, it asks whether that is a further app or a move, and it removes an app with `cadre repo unset --name`. Asked to connect a mobile app, it sets its App Store app and Google Play package with `cadre repo set`, and has the person add a store's key with `cadre app-store key add` or `cadre google-play account add` in their own terminal: Claude Code never handles a store's key. Asked to deploy a repo that runs on Fly or Vercel, it runs `cadre deploy` once the person confirms,
  which checks that a Fly repo's `main` is clean and up to date (a Vercel repo deploys from any pushed commit) and deploys its commit, so Cadre knows which commit each deploy runs. On a repo with several apps it proposes the app the deploy order puts first and passes `--app`, and passes `--all` only when the person asks for every app. It installs the `cadre` CLI from its
  GitHub release (needs `gh`) and updates it with `cadre upgrade`, signs the person in through the browser to the Cadre URL they give, and reports the
  project's URL. Installing cadre installs `superpowers` from `claude-plugins-official` with it.

## Development

```bash
LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb
```

Release a plugin by bumping its version in both `plugins/<name>/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
