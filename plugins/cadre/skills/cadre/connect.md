# Connect a repo to where it deploys

When the person asks to connect a repo to where it deploys ("connect `<repo>` to its Fly app"), or where a repo deploys ("where does `<repo>` deploy?"), with `<repo>` a bare repo name as in a project:

1. Read the repo's targets: `cadre repo show <repo> --json`. "A target's fields" says what each holds. Answer "where does it deploy?" from these fields, and "where does it release?" or "which build is public?" from `stores`.
2. To connect an app, follow the one section for where it runs: "A Fly app", "A Vercel app", "A mobile app" or "Any other host". When the repo already has that app, "Set an app again" applies too.
3. To take an app off, whatever its platform, follow "Remove an app".
4. To connect or disconnect a Fly org, a Vercel team or a store's key, follow the section of that name under its platform.

## A Fly app

A repo can have several Fly apps, such as an umbrella with two.

1. Each app has its own config file and status URL, so ask the person for both for each app, the status URL as "Status URLs" says. A config file other than `fly.production.toml` or `fly.toml` is passed as `--fly-config <file>`.
2. When the repo already has an app and the person names another Fly app, ask whether that is a further app or a move: `--fly-app` alone adds a further app, and a move passes `--name <existing>`, the name of the app that moves, with its new `--fly-app`.
3. Run `cadre repo set <repo> --fly-app <app> --json`, with `--fly-config <file>` and `--status-url <url>` when the app has them. Cadre finds the connected Fly org that lists the app, and keeps it as the target's `account`. The app takes the Fly app's name unless `--name <app>` gives another.
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

Once for each app of the repo (a monorepo has several):

1. Ask the person for the app's Vercel project ID, a short name for it, its folder in the repo and its status URL, as "Status URLs" says.
2. Run `cadre repo set <repo> --vercel-project <id> --name <app> --vercel-dir <folder> --json`, with `--status-url <url>`, no status flag or `--no-status-url`, as "Status URLs" says for Vercel. Cadre finds the connected Vercel team that lists the project, and keeps it as the target's `account`.
3. Read the answer's `status_url`, and relay its `status_url_note` when it kept none.

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
3. Report the stores the JSON body holds, each with the key or account that reads it, and that cadre shows each store's public build within 15 minutes.
4. Once the app is connected, tell the person that cadre reads the git tag of each build: each production build needs `prod-v<version>-<build>` on the commit it was built from, and each staging build `stg-v<version>-<build>`, with the version and build as in the app's `pubspec.yaml` (`prod-v1.8.15-6188`). Then run "Tag each build".

Cadre asks each store which build is public and shows it on its Apps page.

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
   - **Fly:** `--fly-app`, `--fly-config` and `--status-url` each time, and `--name` when the app's name isn't its Fly app's. A `--status-url` left out removes the URL.
   - **Vercel:** `--vercel-dir` and `--status-url` again. A status URL left out is replaced by the production domain when it answers, and removed otherwise. A Vercel target whose `status_url` is `null` keeps none only with `--no-status-url`, so ask the person whether it should stay unmonitored or take the default.
   - **Mobile:** setting the app again replaces its stores. Pass both each time for an app on both stores, and the one it has for an app on one. A store left out is taken off.

## Status URLs

Every app with a server takes a status URL, on Fly and on Vercel. Ask the person for it: a full `https` address that answers 2xx when the app really runs, such as `https://api.example.com/status`. Pass it as `--status-url <url>`. Cadre checks it every 2 minutes, and a PR goes Live once it answers. When `cadre` refuses the URL, tell the person what it printed.

- **Fly.** A Fly app with health checks in its `fly.toml` goes Live without one, but a status URL can check what matters, such as the database. With neither, the app isn't monitored and its PRs stop at Deployed. An app that stops when idle should leave it out.
- **Vercel.** The address answers 2xx without redirecting, with a health path when the app has one. When the person has none, leave both status flags out: cadre takes the project's production domain when `https://<domain>/` answers. The answer's `status_url` says which URL it kept (or `null`), and when it kept none `status_url_note` says why, such as `app.example.com answers 302, so pass --status-url`. Relay the note and ask for a URL that answers, such as the login page a home page redirects to. Pass `--no-status-url` only when the person wants the app not monitored.
- **Mobile.** A mobile app has no server and takes no status URL: cadre refuses `--status-url` for it.

## Tokens and keys

A token or key reaches cadre without passing through Claude Code, in one of two ways:

- the person gives it to cadre in their own terminal, where `cadre fly org add`, `cadre vercel team add`, `cadre app-store key add` and `cadre google-play account add` ask for it without showing it;
- for a Fly org only, the pipe in "Connect a Fly org" carries the token from `fly` to `cadre`.

Never ask the person to send you a token, a key or a key file, and never read one, print it, echo it, pass it as an argument, write it to a file or pipe it any other way.

## A target's fields

Each of the `targets` in `cadre repo show <repo> --json` has:

- `platform`;
- `name`: the app's name in the repo, unique across its platforms;
- `settings`: its `app` and `config` for Fly, its `project` and `dir` for Vercel;
- `status_url`: next to `settings`, not inside it;
- `account`: the Fly org or Vercel team cadre reads it through;
- `tracked`: whether cadre reads its deploys;
- `live`: whether the app answers, `"live"`, `"not_live"`, `"not_checked"`, or `null` with nothing to check;
- `not_live_since`: the time of a `"not_live"` warning, or `null`;
- `last_deploy`: the `commit` and `deployed_at` of the latest deploy cadre saw, or `null`;
- `stores`: a mobile app's stores, empty for any other app. Each has a `label` (`App Store`, `Google Play`), the `app` it is there (the Apple ID or the package name), the `account` cadre reads it with (the key's ID or the service account's email), and `public_build`, the build that is public there: its `version` (or `null` when the store gave none), its `build_number` and `since`, when cadre first saw it. `public_build` is `null` until cadre saw one.

A mobile app's own `account` is `null` and its `tracked` is `false`. That is expected: cadre reads the build's tag, so it knows the build's commit once the tag is pushed, but the PRs a build holds come with a later release of cadre, so the app's merged PRs stay Merged until then. It is not a sign that the app isn't connected.

## When `cadre` refuses

Nothing is connected, or the wrong thing:

- `Fly isn't connected on <server> yet. Add an org with cadre fly org add <org>.`: no Fly org is connected. Ask the person which org runs the app, and offer to connect it as "Connect a Fly org" says.
- `Vercel isn't connected on <server> yet. Add a team with cadre vercel team add <team>.`: no Vercel team is connected. Ask the person which team runs the app, and send them to "Connect a Vercel team".
- `settings.app: isn't an app of a connected Fly org (…)`: no connected org lists the app; the parentheses name the connected orgs. Check the app's name with the person, or connect the org that runs it. When it goes on to say Fly refused the token of an org, or has no such org for its token, make a new token for that org and add it again, as "Connect a Fly org" says.
- `settings.project: isn't a project of a connected Vercel team (…)`: no connected team lists the project; the parentheses name the connected teams. Check the project ID with the person, or connect the team that owns it.
- `Fly refused this token for <org>.` or `Fly has no org <org> that this token can read.`: the token doesn't read that org. Check the org's name with the person, as `fly orgs list` shows it, and make the token for the right org.
- `Vercel refused this token for <team>.` or `Vercel has no team <team> that this token can read.`: the token doesn't read that team. Check the team's name with the person, and have them make a team-scoped token for the right team in the dashboard and add it again, as "Connect a Vercel team" says.
- `App Store: no connected key reads <id> (asked: <key-id>)` or `Google Play: …`: no connected key or account reads that app. The parentheses say what cadre asked. Check the Apple ID or the package name with the person, or have them connect the key or account that owns it, as "Connect a store's key" says.
- `Cadre sends a key or a token over https only. Sign in to an https address first: cadre login --url https://<your cadre>.`: cadre is signed in to an address that isn't https, and nothing was sent. Tell the person what it printed and stop: they sign in again with an https address, then the add runs again.
- `No repo <repo> on <server>.`: cadre knows a repo once a project names it. Check the name with the person, or add the repo to a project as "Change a project" in [project.md](project.md) does.

An app's name:

- `name: is required`: a Vercel app needs `--name <app>`. Ask the person for a short name for it.
- `name: must be lowercase letters, digits, - or _`: a name takes lowercase letters, digits, `-` or `_`, starts with a letter or digit, and runs to 63 characters. Pick one that fits with the person.
- `name: isn't used on this platform`: a host cadre can't read takes no `--name`. Set it with `--platform <name>` alone.
- `name: <name> is already a <Platform> app of <repo>. Unset it first.`: another platform's app of the repo has that name. Pick another name with the person, or unset that app once they agree.
- `settings: <app> is already the <Platform> app of <other>, an app of <repo>. Set <other> instead, or unset it first.`: another app of the repo already points at that Fly app or Vercel project, and `cadre deploy --all` would deploy it twice. When the person meant to change `<other>`, set it with `--name <other>`; otherwise check the app with them.

Removing:

- `<org> still reads <repos>. Unset or move those targets first.` or `<team> still reads <repos>. Unset or move those targets first.`: those repos' apps are read through that Fly org or Vercel team. Name them to the person; unset or move their targets only once they agree.
- `<key-id> still reads <repos>. Add the key that replaces it, set each of those apps again with cadre repo set, then remove this one.`: cadre refuses while an app uses the key or account. Do that in that order with the person, then remove it.
- `name: <repo> has <n> <Platform> apps: <apps>. Pass --name <app>.`: `--platform` alone can't tell which app to remove. Ask the person which one, then run `cadre repo unset <repo> --name <app> --json`.
- `No Fly org <org> on <server>.`, `No Vercel team <team> on <server>.`, `<repo> has no <Platform> target.`, `<repo> has no Vercel target <app>.` or `<repo> has no app <app>.`: there is nothing to remove; check the name with the person.
