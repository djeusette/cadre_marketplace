# Connect a repo to where it deploys

When the person asks to connect a repo to where it deploys ("connect `<repo>` to its Fly app"), or where a repo deploys ("where does `<repo>` deploy?"), with `<repo>` a bare repo name as in a project:

1. Read the repo's targets: `cadre repo show <repo> --json`, as "A target's fields" says. Answer "where does it deploy?" from these fields, and "where does it release?" or "which build is public?" from `stores`.

Then, by what was asked:

- To connect an app, follow the one section for where it runs: "A Fly app", "A Vercel app", "A mobile app" or "Any other host". When the repo already has that app, "Set an app again" applies too.
- To take an app off, whatever its platform, follow "Remove an app".
- To connect or disconnect a Fly org, a Vercel team or a store's key, follow the section of that name under its platform.

## A Fly app

1. Each app has its own config file and status URL, so ask the person for both for each app, the status URL as "Status URLs" says. A config file other than `fly.production.toml` or `fly.toml` is passed as `--fly-config <file>`.
2. When the repo already has an app and the person names another Fly app, ask whether that is a further app or a move: `--fly-app` alone adds a further app, and a move passes `--name <existing>`, the name of the app that moves, with its new `--fly-app`.
3. Run `cadre repo set <repo> --fly-app <app> --json`, with `--fly-config <file>` and `--status-url <url>` when the app has them.
4. After a set without `--name`, read `cadre repo show <repo> --json` again: when the repo now has two or more Fly apps, name them to the person, so an app added by mistake can be unset and the move made with `--name <existing>`.
5. Report the target the JSON body holds.

### Connect a Fly org

Cadre reads Fly with one read-only token per Fly org, kept on its server for the whole team.

1. Ask the person first, naming the org.
2. Once they agree, run:

   ```bash
   fly tokens create readonly -o <org> -n cadre | cadre fly org add <org> --json
   ```

   The token goes through the pipe, unseen, as "Tokens and keys" says. When the person already has a token, they add it themselves: `cadre fly org add <org>` in their own terminal asks for it without showing it.
3. Report the org's `name` and the `apps` field, how many apps its token reads, then set the target that was waiting for it.

When `fly` is missing or not signed in, it makes no token and cadre prints `No token given. Pipe it in, or type it when asked.`: tell the person to install `fly` or run `fly auth login`, then run the pipe again.

`cadre fly org remove <org> --json` disconnects an org, once the person confirms.

## A Vercel app

Once for each app of the repo:

1. Ask the person for the app's Vercel project ID, a short name for it, its folder in the repo and its status URL, as "Status URLs" says.
2. Run `cadre repo set <repo> --vercel-project <id> --name <app> --vercel-dir <folder> --json`, with `--status-url <url>`, no status flag or `--no-status-url`, as "Status URLs" says for Vercel.
3. Read the answer's `status_url` as "Status URLs" says for Vercel.

`cadre deploy <repo>` deploys it, as [deploy.md](deploy.md) says.

### Connect a Vercel team

Cadre reads Vercel with one team-scoped token per Vercel team, kept on its server for the whole team. `vercel tokens add` can only make a token for the whole account, so the person makes a team-scoped one in the dashboard and adds it themselves, as "Tokens and keys" says.

1. Name the team to the person and tell them to make a team-scoped token in Vercel's dashboard (open Account Settings, then Tokens, and create a token scoped to the team), and to run `cadre vercel team add <team>` in their own terminal, where it asks for the token without showing it.
2. Once they say it is added, set the app that was waiting for it.

`cadre vercel team remove <team> --json` disconnects a team, once the person confirms.

## A mobile app

A mobile app is connected to one store or both.

1. Ask the person for the App Store app's Apple ID, the number in its App Store Connect address (`6443635924`), and for the Google Play package name (`com.example.app`).
2. Run `cadre repo set <repo> --app-store-app <id> --play-package <name> --json`, with one store's flag alone when the app has only that store, and with `--name <app>` when the repo has more than one app.
3. Report the stores the JSON body holds, each with the key or account that reads it, and that cadre shows each store's public build on its Apps page within 15 minutes.
4. Once the app is connected, tell the person that cadre reads the git tag of each build: each production build needs `prod-v<version>-<build>` on the commit it was built from, and each staging build `stg-v<version>-<build>`, with the version and build as in the app's `pubspec.yaml` (`prod-v1.8.15-6188`). Then run "Tag each build".

### Tag each build

1. Read `cadre repo show <repo> --json`, and for each of the app's stores its `public_build`.
2. When `public_build` is `null`, the store has no public build yet: there is nothing to tag.
3. Otherwise read `public_build.tag`. When it names a tag, the build is tagged.
4. When it is `null`, a public build is a production build. Ask the person for the commit the build was made from, since cadre has no commit for an untagged build.
5. The tag is `prod-v<version>-<build>`, with the version and build taken from that store's `public_build` (its `version` and `build_number`). When `version` is `null` (Google Play gives none), read the version from `pubspec.yaml` at that commit. Give the person the tag and this command, for them to run in a checkout of that repo: `git tag <tag> <commit> && git push origin <tag>`. The person runs it, never you.

### Connect a store's key

1. Tell the person to run, in their own terminal and following cadre's Setup page (`/setup`), `cadre app-store key add <key-id> --issuer <issuer-id>`, which asks for the key's `.p8` file, or `cadre google-play account add`, which asks for the service account's JSON key file. The key file stays with them, as "Tokens and keys" says.
2. Once they say it is added, set the app that was waiting for it.
3. When the new key replaces an App Store Connect key, set again each app the old key read, as "Set an app again" says, so it takes the new key. The old key stays connected until then. A Google Play account added again with a new JSON key keeps its apps.

`cadre app-store key remove <key-id> --json` and `cadre google-play account remove <email> --json` disconnect a key or an account, once the person confirms.

## Any other host

For any host other than Fly or Vercel, `cadre repo set <repo> --platform <name> --json` records it, and it shows as not tracked: cadre can't read its deploys yet. `cadre repo unset <repo> --platform <name> --json` removes it.

## Remove an app

`cadre repo unset <repo> --name <app> --json` removes any app, whatever its platform, once the person confirms. The app's recorded deploys go with it.

## Set an app again

Setting an app again (the same name) replaces its settings, so every one of them is passed again:

1. Read what is there before setting it: the target's `settings` and its `status_url`, in `cadre repo show <repo> --json`.
2. Carry them over, passing each again with what changes:
   - **Fly:** every flag `cadre help repo set` says a set replaces.
   - **Vercel:** `--vercel-dir` and `--status-url` again. A status URL left out is replaced by the production domain when it answers, and removed otherwise. A Vercel target whose `status_url` is `null` keeps none only with `--no-status-url`, so ask the person whether it should stay unmonitored or take the default.
   - **Mobile:** setting the app again replaces its stores. Pass both each time for an app on both stores, and the one it has for an app on one. A store left out is taken off.

## Status URLs

Every app with a server takes a status URL, on Fly and on Vercel. Ask the person for it: a full `https` address that answers 2xx when the app really runs, such as `https://api.example.com/status`. Cadre checks it every 2 minutes, and a PR goes Live once it answers.

- **Fly.** A Fly app with health checks in its `fly.toml` goes Live without one, but a status URL can check what matters, such as the database. With neither, the app isn't monitored and its PRs stop at Deployed. An app that stops when idle should leave it out.
- **Vercel.** The address answers 2xx without redirecting, with a health path when the app has one. When the person has none, leave both status flags out: cadre takes the project's production domain when `https://<domain>/` answers. The answer's `status_url` says which URL it kept (or `null`), and when it kept none `status_url_note` says why, such as `app.example.com answers 302, so pass --status-url`. Give the person the note and ask for a URL that answers, such as the login page a home page redirects to. Pass `--no-status-url` only when the person wants the app not monitored.
- **Mobile.** A mobile app has no server and takes no status URL: cadre refuses `--status-url` for it.

## Tokens and keys

A token or key reaches cadre without passing through Claude Code, in one of two ways:

- the person gives it to cadre in their own terminal, where `cadre fly org add`, `cadre vercel team add`, `cadre app-store key add` and `cadre google-play account add` ask for it without showing it;
- for a Fly org only, the pipe in "Connect a Fly org" carries the token from `fly` to `cadre`.

Ask the person only for names and IDs. You never see or carry a token, a key or a key file: when the person offers one in chat, leave it unused and send them to its command above, in their own terminal.

## A target's fields

In `cadre repo show <repo> --json`, each of the `targets` reads as its field names say, apart from these:

- `name` is unique across the repo's platforms;
- `status_url` sits next to `settings`, not inside it;
- `live` is `"live"`, `"not_live"`, `"not_checked"`, or `null` with nothing to check;
- `stores` is empty for any app but a mobile one, and a store's `public_build` is `null` until cadre saw one.

A mobile app's own `account` is `null` and its `tracked` is `false` until a build public on every store has its tag. That is expected: cadre reads the build's tag, so it knows the build's commit once the tag is pushed. From then on the app is tracked and its card lists the PRs each build holds; until then its merged PRs stay Merged. It is not a sign that the app isn't connected.

## When `cadre` refuses

Nothing is connected, or the wrong thing:

- `Fly isn't connected on <server> yet. Add an org with cadre fly org add <org>.`: no Fly org is connected. Ask the person which org runs the app, and offer to connect it as "Connect a Fly org" says.
- `Vercel isn't connected on <server> yet. Add a team with cadre vercel team add <team>.`: no Vercel team is connected. Ask the person which team runs the app, and send them to "Connect a Vercel team".
- `settings.app: isn't an app of a connected Fly org (…)`: no connected org lists the app; the parentheses name the connected orgs. Check the app's name with the person, or connect the org that runs it. When it goes on to say Fly refused the token of an org, or has no such org for its token, make a new token for that org and add it again, as "Connect a Fly org" says.
- `settings.project: isn't a project of a connected Vercel team (…)`: no connected team lists the project; the parentheses name the connected teams. Check the project ID with the person, or connect the team that owns it.
- `Fly refused this token for <org>.` or `Fly has no org <org> that this token can read.`: the token doesn't read that org. Check the org's name with the person, as `fly orgs list` shows it, and make the token for the right org.
- `Vercel refused this token for <team>.` or `Vercel has no team <team> that this token can read.`: the token doesn't read that team. Check the team's name with the person, and have them make a team-scoped token for the right team in the dashboard and add it again, as "Connect a Vercel team" says.
- `App Store: no connected key reads <id> (asked: <key-id>)` or `Google Play: …`: no connected key or account reads that app. The parentheses say what cadre asked. Check the Apple ID or the package name with the person, or have them connect the key or account that owns it, as "Connect a store's key" says.
- `Cadre sends a key or a token over https only. Sign in to an https address first: cadre login --url https://<your cadre>.`: cadre is signed in to an address that isn't https, and nothing was sent. Sign in again as "Sign in" in [SKILL.md](SKILL.md) says, with the person's https URL; then the person runs their add again in their own terminal, or you run the Fly pipe again.
- `No repo <repo> on <server>.`: cadre knows a repo once a project names it. Check the name with the person, or add the repo to a project as "Change a project" in [project.md](project.md) does.

An app's name:

- `name: is required`: a Vercel app needs `--name <app>`. Ask the person for a short name for it.
- `name: isn't used on this platform`: a host cadre can't read takes no `--name`. Set it with `--platform <name>` alone.
- `name: must be lowercase letters, digits, - or _`: a name takes lowercase letters, digits, `-` or `_`, starts with a letter or digit, and runs to 63 characters. Pick one that fits with the person.
- `settings: <app> is already the <Platform> app of <other>, an app of <repo>. Set <other> instead, or unset it first.`: another app of the repo already points at that Fly app or Vercel project, and `cadre deploy --all` would deploy it twice. When the person meant to change `<other>`, set it with `--name <other>`; otherwise check the app with them.

Removing:

- `<org> still reads <repos>. Unset or move those targets first.` or `<team> still reads <repos>. Unset or move those targets first.`: those repos' apps are read through that Fly org or Vercel team. Name them to the person; unset or move their targets only once they agree.
- `<key-id> still reads <repos>. Add the key that replaces it, set each of those apps again with cadre repo set, then remove this one.`: cadre refuses while an app uses the key or account. Do that in that order with the person, then remove it.
