---
name: cadre
description: Use when the person asks to register, create or track a project, feature or milestones in Cadre, to read, write or update a milestone's spec in Cadre ("update the spec of <project>/<n>"), to change, reorder, rename or drop a project or its milestones in Cadre, to start a milestone ("start milestone <project>/<n>"), to link a pull request to a milestone, to connect a repo to where it deploys, or a Fly org or a Vercel team, in Cadre ("connect <repo> to its Fly app", "connect <repo> to its Vercel project", "where does <repo> deploy?"), or a mobile app to its stores, to deploy a repo that runs on Fly or Vercel, to tick a Before deploying item, to implement a spec or plan that says it is tracked in Cadre, or to sign in to Cadre.
---

# Cadre

Cadre shows where every milestone of a feature stands, on every repo, in deploy order. You register a project there from the feature's spec with the `cadre` CLI: one milestone per increment of the spec, each with the repos it touches, its own spec and a link to its designs. When the feature has no spec yet, you brainstorm it with the person first.

## Before you start

Run `gh auth status`. When it fails, tell the person to run `gh auth login`, and stop. The CLI is downloaded with `gh`.

## Install or update the CLI

Run `cadre version`.

- When the command is missing, run:

  ```bash
  mkdir -p ~/.local/bin
  gh release download -R djeusette/cadre_cli --pattern "cadre_$(uname -s)_$(uname -m).tar.gz" -O - | tar -xz -C ~/.local/bin cadre
  ```

  Then run `cadre version` again. When the command is still missing, `~/.local/bin` is not on the person's `PATH`: tell them to add it, and stop.
- When it reports a version below `0.19.0`, run `cadre upgrade`. It replaces that `cadre` with the latest release and prints `Upgraded cadre from <old> to <new>.` When it fails, tell the person what it printed, and stop.

## Sign in

Run `cadre whoami --json`. It succeeds when the exit code is 0 and the JSON holds an `email`.

- `Not signed in. Run cadre login --url <url>.`: ask the person for their Cadre URL, the address they open Cadre at in their browser, such as `https://cadre.example.com`. Never guess it. Then run `cadre login --url <url>` with it. It waits up to 10 minutes for the person to click **Allow**, but the Bash tool stops a command after 2 minutes by default and shows no output until the command exits. So run it in the background (Bash `run_in_background`), or with a `timeout` of 600000 ms. Read its first two output lines, `Opening <uri> in your browser.` and `Check that the page shows this code: <code>`, and tell the person the URL and the code: they check that the page shows that code, then click **Allow**. Then wait for the command to exit and read `Signed in as <email>.`
- `Your key for <url> is no longer valid. Run cadre login --url <url>.`: run `cadre login --url <url>` with the URL the message names, as above.
- `The code expired. Run cadre login --url <url> again.`: run it again with the same URL.
- `--url must be an http:// or https:// URL with a host, …`: the URL is not a full address; ask the person for it again.

The person never types or copies a key.

## Create a project

1. Get the feature's spec:
   - When the person names a spec that already has an `## End goal` and an `## Increments` section, build from it, without the questions.
   - Never pick a spec on your own: when one in `docs/superpowers/specs/` might be this feature, ask the person whether it is.
   - Otherwise, read [brainstorm.md](brainstorm.md) and brainstorm the feature with the person as it says. It ends with the spec committed.
2. Build the project from the spec:
   - `name`: the spec's title without ` — design`.
   - `slug`: the name in kebab case, lowercase letters and digits only.
   - `end_goal`: the text of the End goal section.
   - `milestones`: one per `### Increment`, in spec order, its `title` the increment's title. Its `repos` are the repositories the increment changes, in deploy order: the order the spec's Consumers and deploy-order lines give, the repo that must deploy first listed first.
   Repo names are bare, `shop-api` and not `acme/shop-api`, and match the limits below. The current repository (`gh repo view --json name -q .name`) is a repo of every increment whose Code files live in it. A file path is never a repo. Consumers can say "none".
   Apps in `repos`. A step can name an app, as `repo/app`. Read `cadre repo show <repo> --json` for each repo. A repo with one app stays a bare repo, unless the milestone also expects an app of it that isn't connected yet: then name each app the milestone expects as `repo/app`, the API before the frontend. A repo with several apps gets one `repo/app` entry per app the milestone expects, in deploy order, the API before the frontend, for example `"repos": ["kinfield/kinfield", "kinfield/kinfield-family"]`. When the spec doesn't say which apps, ask the person. An app that isn't connected yet can be named. A milestone never lists a repo bare and with one of its apps. When `cadre repo show` prints `No repo <repo> on <server>.`, Cadre doesn't know the repo yet. It has no app there, so it stays a bare `repo` unless the spec names its apps. Don't ask the person about that error.
   The feature spec says it is tracked in Cadre, on the line under its title, so whoever implements it uses this skill:

   ```markdown
   > Tracked in Cadre as `<slug>`. Implement each increment with the `cadre:cadre` skill ("start milestone <slug>/<i>"), which plans it and links its pull request to its milestone.
   ```

   Add the line when the spec lacks it, and commit it as step 5 commits a correction.
3. Design every milestone: create one Claude Design canvas for the project, with one page per milestone. A milestone without a screen gets a diagram as its page instead: its data flow or its API contract. Keep the canvas link and each milestone's design link, built as "Link a milestone to its design" says.
4. Write one spec per milestone, as the next section describes.
5. Play every milestone back one last time, as it will be registered: its title, its repos in deploy order, its consumers, what it delivers and its design link. Take a repo name only from the spec or from the person, and ask when unsure. Register nothing until the person approves them. Fix what they correct first. When a correction changes the feature spec, update the spec. If the brainstorm committed it, commit only that file again with `git commit -m "docs: <feature> design" -- <path>`, and never push. If the person named it, leave the commit to them.
6. Add them to the project: `canvas_url` is the canvas link and, per milestone, `spec` is its markdown and `design_url` its design link.
7. Write the JSON to a temporary file and run `cadre project create <file> --json`.
   When it prints `Your key for <url> is no longer valid. Run cadre login --url <url>.`, go back to Sign in, then run it again.
8. On a `422`, the CLI prints one `<path>: <message>` line per error, for example `milestones.1.repos.0: …`. Fix the fields those paths name, then run the command again. When you change the `slug`, change it on the spec's tracking line too. Error paths are 0-based positions in the JSON arrays: `milestones.1.repos.0` is the first repo of the second milestone, while milestone numbers shown elsewhere start at 1.
9. Report the `url` field of the JSON body the command printed, and remind the person to share the canvas with the team: you can't change its sharing.

```json
{
  "name": "Wish reminders",
  "slug": "wish-reminders",
  "end_goal": "Members never miss a wish that is about to expire.",
  "milestones": [
    {
      "title": "Members get a reminder before a wish expires",
      "repos": ["shop-api"],
      "spec": "# Wish reminders 1: Members get a reminder before a wish expires\n\n...",
      "design_url": "https://claude.ai/artifact/…#page-…"
    },
    {
      "title": "Members choose when they are reminded",
      "repos": ["shop-api", "shop-mobile"],
      "spec": "# Wish reminders 2: Members choose when they are reminded\n\n...",
      "design_url": "https://claude.ai/artifact/…#page-…"
    }
  ],
  "canvas_url": "https://claude.ai/artifact/…"
}
```

## Write a milestone's spec

A milestone's spec is markdown that starts with `# <name> <n>: <title>`, for example `# Wish reminders 2: Members choose when they are reminded`, and the line under it says it is tracked in Cadre:

```markdown
> Tracked in Cadre as `<slug>/<n>`. Implement it with the `cadre:cadre` skill ("start milestone <slug>/<n>"), which plans it and links its pull request to the milestone.
```

Then it gives that increment's Delivers, Deployable alone, Consumers and Code files from the feature spec, and whatever the feature spec's other sections say about this milestone: its screens, data, API, rules and errors. It has no `## Increments` section and no `- [ ] Not shipped` line.

## Link a milestone to its design

A milestone's design link opens the canvas on that milestone's page. Read the page's `id` from the `pages` list of the canvas's `project/canvas.json`, then build the link with [design_link.rb](design_link.rb), in this skill's folder:

```bash
ruby <this skill's folder>/design_link.rb <canvas_url> --page <id>
```

- A milestone whose designs are one board on a page it shares links that board: `--board <file>`, with the board's key in `boards`, such as `M3.dc.html`.
- A milestone with no page or board of its own keeps the canvas link.
- The link holds a hash of the page's `id` or the board's file name. When one of them changes, the link opens the canvas's default view, so build it again.
- When `ruby` is missing, ask the person to open the page in the canvas and send you what their address bar shows: it is the same link.

## Update a milestone's spec

When the person asks to "update the spec of `<project>/<n>`", for example because a card in Cadre says "No spec or designs yet", or because an earlier milestone taught something:

1. Pull the spec into a temporary `.md` file: `cadre spec pull <project>/<n> -o <file> --json`. Keep the JSON's `version` and `updated_by`. The file holds the spec exactly as Cadre stores it.
2. On `<project>/<n> has no spec yet.`, nothing is written: write the milestone's spec into the file as the section above says, then push it without a base, `cadre spec push <project>/<n> <file> --json`, and go to step 5.
3. Otherwise edit the pulled file with the person: what they asked for, and what earlier milestones taught. Keep its title line and its sections. A push changes only the spec: a design link is set when the project is created.
4. Push it with the version you pulled as its base: `cadre spec push <project>/<n> <file> --base <version> --json`. Cadre keeps the file exactly as written, as the milestone's newest spec.
5. Report the `url` field of the JSON body and the change in one or two lines. The milestone's card in Cadre now offers the text the push replaced as its previous version.

On `The spec of <project>/<n> changed since you pulled it. Pull it again.`, someone pushed after your pull. Pull again, tell the person who (`updated_by`), apply the same edit to the new text, and push with the new `version`. For a further change after a push, pull again first: each push needs the newest `version` as its base.

To show the person a spec, run `cadre spec pull <project>/<n>` and show what it prints.

On `No milestone <project>/<n> on <server>.`, check the project's slug and the milestone's number with the person. On `spec: …`, the file broke a limit below: fix it and push again. On `Your key for <url> is no longer valid. Run cadre login --url <url>.`, go back to Sign in, then push again.

## Change a project

When the person asks to change a project in Cadre, for example to rename it, reorder or rename its milestones, change their repos, design links or deploy order, add a milestone, or drop the project:

1. Pull the project into a temporary `.json` file: `cadre project pull <slug> -o <file> --json`. Keep the JSON's `version`. When `archived` is true, ask the person whether to bring the project back first. When they agree, run `cadre project unarchive <slug>` and continue with the same file: unarchiving doesn't change the version.
2. Edit the file with the person:
   - the name, end goal, home repo (one of the milestones' repos) and canvas link;
   - reorder milestones by moving their entries;
   - rename them, and change their design links, repos and deploy order;
   - name their apps, as "Create a project" says under "Apps in `repos`".
   - add one as an entry with no `number`, no `spec` and no `design_url`: Cadre numbers it, and its spec and page come after the update (step 5).

   Keep every `number`, the `slug` and the `version` as pulled. Never put a `spec` on a milestone that has a `number`: use "Update a milestone's spec".
3. Leaving a milestone out archives it, and its number is never used again: say so, and leave one out only once the person agrees.
4. Play the change back in a few lines, and apply it once the person approves: `cadre project update <file> --json`. Report the new `version` and the `url`.
5. For each milestone you added, once the update has succeeded:
   - Pull the project again: `cadre project pull <slug> -o <file> --json`. The new milestone is the entry whose `number` was not in the file you sent. Its number follows the highest one the project ever used, archived milestones included, so you could not know it before.
   - Write its spec as "Write a milestone's spec" says, with that number, and push it without a base, as it has no spec yet: `cadre spec push <slug>/<n> <spec-file> --json`.
   - Draw its page in the project's design canvas, as "Create a project" does for every milestone, then put its design link, built as "Link a milestone to its design" says, in the pulled file as its `design_url`. Pull once more for the new `version`, edit that one entry, and run `cadre project update <file> --json`.
   - Report the new number to the person, with the `url`.
6. On `<slug> changed since you pulled it (version <n>, now <m>). Pull it again.`, pull again, redo the edit on the new file, play it back, and update.
7. On `<slug> is archived. Run cadre project unarchive <slug> first.`, ask the person whether to bring the project back. When they agree, run `cadre project unarchive <slug>` and update again with the same file.
8. To drop a project ("drop gift-wrapping"): confirm with the person, run `cadre project archive <slug>`, and say it hides the project from the Overview, and that `cadre project unarchive <slug>` brings it back.
9. On `No project <slug> on <server>.`, check the slug with the person. On `milestones.<i>.number: …` or another `path: message`, fix that entry and update again. On `Your key for <url> is no longer valid. Run cadre login --url <url>.`, go back to Sign in, then retry.

## Start a milestone

When the person asks to "start milestone `<slug>/<n>`", or to start work on a milestone in Cadre:

1. Pull the project into a temporary `.json` file: `cadre project pull <slug> -o <tmp>.json --json`. The milestone's `repos` are its steps in deploy order: a repo/app entry is its repo, one step of it per app. Then pull its spec into a temporary `.md` file: `cadre spec pull <slug>/<n> -o <tmp>.md --json`. On `<slug>/<n> has no spec yet.`, write its spec first, as "Update a milestone's spec" says, then pull it again.
2. Run `gh repo view --json name -q .name`. When this repo is one of the milestone's repos, work on this repo's part. Otherwise, name the milestone's repos to the person, in deploy order, and stop: the milestone starts in the first step with no pull request yet. To find it, run in each repo of the milestone, in deploy order, `gh pr list --repo <owner>/<repo> --state all --search '"Cadre: <slug>/<n>" in:body' --json number,state,body`, where `<owner>` is the GitHub owner of this checkout, `gh repo view --json owner -q .owner.login`: Cadre's repos all live under one org, so it serves the milestone's other repos too. The search is a text search, so `"Cadre: <slug>/2"` also matches `<slug>/20`: read each body's `Cadre:` line and keep only the pull requests whose line names exactly `<slug>/<n>`, optionally followed by an app. A pull request whose line names an app holds that app's step. One whose line names no app holds every step of its repo. A closed, unmerged pull request holds nothing. The milestone starts at the first step none holds. When that is unclear, ask the person. Each other repo of the milestone is started the same way, in its own session in that repo.
3. When `git branch --show-current` prints the repo's default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), switch to the milestone's branch: `git switch -c <slug>-<n>`, or `git switch <slug>-<n>` when it already exists. When the pull request is for one app of several, the branch is `<slug>-<n>-<app>` instead: `git switch -c <slug>-<n>-<app>`, or `git switch <slug>-<n>-<app>` when it already exists. The plan and its pull request start from that branch, so the record lands with them, never on the default branch.
4. Copy the spec into this repo's `docs/superpowers/specs/<slug>-<n>.md` as a record, creating the folder when it is missing, and commit only that file: `git add <path>`, then `git commit -m "docs: spec of <slug>/<n>" -- <path>`. When `<path>` already holds this text, as when a milestone is started again, skip the commit: there is nothing to commit. Cadre's copy stays the original, and cadre never reads this one.
5. Plan this repo's part with `superpowers:writing-plans`, giving it the spec copy's path and these rules on top:
   - plan only this repo's part of milestone `<slug>/<n>`;
   - one plan and one pull request per repo, or per app when the milestone's steps name that repo's apps and the work splits that way;
   - the pull request's description has a line that reads exactly `Cadre: <slug>/<n>`, or `Cadre: <slug>/<n> <app>` for a pull request for one app, which links the pull request to the milestone in Cadre. The app is its name in Cadre, as `cadre repo show` lists it: lowercase letters, digits, `-` or `_`. A line whose app isn't such a name links nothing;
   - when the change needs something before it ships, such as a new env var or secret, another repo deployed first, or a manual step, the pull request's description lists it under a heading line `## Before deploying`, as a task list with one `- [ ]` item for each. The person ticks an item in GitHub once it's done. A change that needs nothing has no section;
   - the plan's header says it is tracked in Cadre, on the line under its title, so whoever executes it uses this skill:

     ```markdown
     > **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n>`.
     ```

     When the plan is for one app, the header's last line names it:

     ```markdown
     > **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n> <app>`.
     ```
6. Execute the plan as `superpowers:writing-plans` offers.

On `No project <slug> on <server>.` or `No milestone <slug>/<n> on <server>.`, check the slug and number with the person. On `Your key for <url> is no longer valid. Run cadre login --url <url>.`, go back to Sign in, then retry.

### Track a milestone's implementation

A spec or plan tracked in Cadre says so on the line under its title. When you implement one, for example while executing such a plan:

- Its pull request's description has the line `Cadre: <slug>/<n>`, on a line of its own, with the app after it when the pull request is for one app: `Cadre: <slug>/<n> <app>`, the app's name in Cadre. When the pull request is already open without it, add it: write `gh pr view <pr-url> --json body -q .body` to a temporary file, add the line, then run `gh pr edit <pr-url> --body-file <file>`.
- When the change needs something before it ships, such as a new env var or secret, another repo deployed first, or a manual step, the pull request's description lists it under a heading line `## Before deploying`, as a task list with one `- [ ]` item for each. The person ticks an item in GitHub once it's done. A change that needs nothing has no section.
- A feature spec names only its project, `<slug>`: its increment `<i>` is milestone `<slug>/<i>`. Start it as "Start a milestone" says, so its plan says it is tracked too.

### Link a pull request by hand

A pull request opened without the `Cadre:` line, or before the cadre GitHub App was installed, is linked with `cadre pr link <pr-url> <slug>/<n> --json`, and `cadre pr link <pr-url> --none --json` unlinks it. Cadre reads the pull request from GitHub then. To name the app the pull request is for, add `--app <app>`: `cadre pr link <pr-url> <slug>/<n> --app <app> --json`. The JSON body then has an `app` field, null when none. Report the `project_url` field of the JSON body. A `Cadre:` line in its description wins at its next sync, so edit the line rather than fight it.

- `No milestone <slug>/<n> on <server>.`: check the slug and number with the person.
- `GitHub has no pull request at <url>.`: check the URL with the person.
- `GitHub isn't connected on <server> yet. …`: tell the person, and stop.
- `Cadre couldn't reach GitHub. …`: try again later.
- `app: must be lowercase letters, digits, - or _`: check the app's name with the person. The app is its name in Cadre, as `cadre repo show` lists it.
- `url: is in a repo no project names`: the repo needs to be in a project first, as "Change a project" adds it.
- `Your key for <url> is no longer valid. Run cadre login --url <url>.`: go back to Sign in, then retry.

## Connect a repo to where it deploys

When the person asks to connect a repo to where it deploys ("connect `<repo>` to its Fly app"), or where a repo deploys ("where does `<repo>` deploy?"), with `<repo>` a bare repo name as in a project:

1. Read the repo's targets: `cadre repo show <repo> --json`. Each of its `targets` has a `platform`, a `name`, the app's name in the repo, unique across its platforms, its `settings` (Fly's is `app`, Vercel's are `project` and `dir`), an `account`, the Fly org or Vercel team cadre reads it through, `tracked`, whether cadre reads its deploys, `live`, whether the app answers (`"live"`, `"not_live"`, `"not_checked"`, or `null` with nothing to check), `not_live_since`, the time of a `"not_live"` warning, or `null`, and `last_deploy`, the `commit` and `deployed_at` of the latest deploy cadre saw, or `null`. Answer "where does it deploy?" from them. Before setting an app again, read what is there: the target's `settings` (its `app` and `config` for Fly, its `project` and `dir` for Vercel) and its `status_url`, which sits next to `settings`, not inside it. Then carry them over: a Vercel target whose `status_url` is `null` keeps none only with `--no-status-url`, so ask the person whether it should stay unmonitored or take the default.
2. Connect a Fly app: `cadre repo set <repo> --fly-app <app> --json`. Cadre finds the connected Fly org that lists the app, and keeps it as the target's `account`. The app takes the Fly app's name unless `--name <app>` gives another. A repo can have several Fly apps, such as an umbrella with two. When the repo already has an app and the person names another Fly app, ask whether that is a further app or a move: `--fly-app` alone adds a further app, and a move passes `--name <existing>`, the name of the app that moves, with its new `--fly-app`. After a set without `--name`, read `cadre repo show <repo> --json` again: when the repo now has two or more Fly apps, name them to the person, so an app added by mistake can be unset and the move made with `--name <existing>`. Setting an app again (the same name) replaces its settings, so pass `--fly-app`, `--fly-config` and `--status-url` each time, and `--name` when the app's name isn't its Fly app's: a `--status-url` left out removes the URL. A repo that deploys with a config file other than `fly.production.toml` or `fly.toml` is set with `cadre repo set <repo> --fly-app <app> --fly-config <file> --json`. Each app has its own config file and status URL, so ask for both for each app.

   Every app with a server takes a status URL, on Fly and on Vercel. Ask the person for it: a full `https` address that answers 2xx when the app really runs, such as `https://api.example.com/status`. Pass it as `--status-url <url>`, with `--fly-config <file>` when the repo has one: `cadre repo set <repo> --fly-app <app> --status-url <url> --json`. Cadre checks it every 2 minutes, and a PR goes Live once it answers. A Fly app with health checks in its `fly.toml` goes Live without one, but a status URL can check what matters, such as the database. With neither, the app isn't monitored and its PRs stop at Deployed. An app that stops when idle should leave it out. A mobile app has no server: `--status-url` is refused for it, as step 9 says. When `cadre` refuses the URL, tell the person what it printed. Report the target the JSON body holds.
3. For any host other than Fly or Vercel, `cadre repo set <repo> --platform <name> --json` records it, and it shows as not tracked: cadre can't read its deploys yet. `cadre repo unset <repo> --platform <name> --json` removes it. `cadre repo unset <repo> --name <app> --json` removes any app, whatever its platform, once the person confirms. The app's recorded deploys go with it.
4. Cadre reads Fly with one read-only token per Fly org, kept on its server for the whole team. To connect an org, ask the person first, naming the org. Once they agree, run:

   ```bash
   fly tokens create readonly -o <org> -n cadre | cadre fly org add <org> --json
   ```

   The token goes through the pipe: never print it, echo it, pass it as an argument or write it to a file. When the person already has a token, they add it themselves: `cadre fly org add <org>` in their own terminal asks for it without showing it. Report the org's `name` and the `apps` field, how many apps its token reads, then set the target that was waiting for it. When `fly` is missing or not signed in, it makes no token and cadre prints `No token given. Pipe it in, or type it when asked.`: tell the person to install `fly` or run `fly auth login`, then run the pipe again.
5. `cadre fly org remove <org> --json` disconnects an org, once the person confirms.
6. Connect a Vercel app, once for each app of the repo (a monorepo has several): ask the person for the app's Vercel project ID, a short name for it and its folder in the repo, then run `cadre repo set <repo> --vercel-project <id> --name <app> --vercel-dir <folder> --json`. Cadre finds the connected Vercel team that lists the project, and keeps it as the target's `account`. Ask for its status URL too, as step 2 does for Fly: a full `https` address that answers 2xx without redirecting, with a health path when the app has one. Pass it as `--status-url <url>`. When the person has none, leave both status flags out: cadre takes the project's production domain when `https://<domain>/` answers, the answer's `status_url` says which URL it kept (or `null`), and when it kept none `status_url_note` says why, such as `app.example.com answers 302, so pass --status-url`. Relay the note and ask for a URL that answers, such as the login page a home page redirects to. Pass `--no-status-url` only when the person wants the app not monitored. Setting an app again replaces its settings, so pass `--vercel-dir` and `--status-url` again: a status URL left out is replaced by the production domain when it answers, and removed otherwise. `cadre deploy <repo>` deploys it, as "Deploy a repo" says.
7. Cadre reads Vercel with one team-scoped token per Vercel team, kept on its server for the whole team. A Vercel token is never handled by Claude Code: `vercel tokens add` can only make a token for the whole account, so the person makes a team-scoped one in the dashboard. To connect a team, name the team to the person and tell them to make a team-scoped token in Vercel's dashboard (open Account Settings, then Tokens, and create a token scoped to the team), and to run `cadre vercel team add <team>` in their own terminal, where it asks for the token without showing it. Never ask them to send you the token, and never pipe, echo, print or write one. Once they say it is added, set the app that was waiting for it.
8. `cadre vercel team remove <team> --json` disconnects a team, once the person confirms. A Vercel app is removed by name, as step 3 says: `cadre repo unset <repo> --name <app> --json`.
9. Connect a mobile app, with one store or both: ask the person for the App Store app's Apple ID, the number in its App Store Connect address (`6443635924`), and for the Google Play package name (`com.example.app`), then run `cadre repo set <repo> --app-store-app <id> --play-package <name> --json`, with `--name <app>` when the repo has more than one app. Setting the app again replaces its stores, so pass both each time: a store left out is taken off. A mobile app takes no status URL, and cadre refuses `--status-url` for it. Cadre asks each store every 15 minutes which build is public, and shows it on its Apps page.
10. A store's key is never handled by Claude Code, as a Vercel token isn't. To connect a store, tell the person to run `cadre app-store key add <key-id> --issuer <issuer-id>`, which asks for the key's `.p8` file, or `cadre google-play account add`, which asks for the service account's JSON key file, in their own terminal, following cadre's Setup page (`/setup`). Never ask them to send you a key file, and never read one. Once they say it is added, set the app that was waiting for it.
11. `cadre app-store key remove <key-id> --json` and `cadre google-play account remove <email> --json` disconnect a key or an account, once the person confirms. Cadre refuses while an app uses it.

When a command fails, it prints one of these:

- `Fly isn't connected on <server> yet. Add an org with cadre fly org add <org>.`: no Fly org is connected. Ask the person which org runs the app, and offer to connect it as in step 4.
- `Vercel isn't connected on <server> yet. Add a team with cadre vercel team add <team>.`: no Vercel team is connected. Ask the person which team runs the app, and send them to step 7.
- `settings.project: isn't a project of a connected Vercel team (…)`: no connected team lists the project; the parentheses name the connected teams. Check the project ID with the person, or connect the team that owns it.
- `Vercel refused this token for <team>.` or `Vercel has no team <team> that this token can read.`: the token doesn't read that team. Check the team's name with the person, and have them make a team-scoped token for the right team in the dashboard and add it again, as in step 7.
- `<team> still reads <repos>. Unset or move those targets first.`: those repos' Vercel projects are read through that team. Name them to the person; unset or move their targets only once they agree.
- `No Vercel team <team> on <server>.` or `<repo> has no Vercel target <app>.`: there is nothing to remove; check the name with the person.
- `Cadre couldn't reach Vercel. Try again in a minute.`: try again in a minute.
- `settings.app: isn't an app of a connected Fly org (…)`: no connected org lists the app; the parentheses name the connected orgs. Check the app's name with the person, or connect the org that runs it. When it goes on to say Fly refused the token of an org, or has no such org for its token, make a new token for that org and add it again, as in step 4.
- `Fly refused this token for <org>.` or `Fly has no org <org> that this token can read.`: the token doesn't read that org. Check the org's name with the person, as `fly orgs list` shows it, and make the token for the right org.
- `<org> still reads <repos>. Unset or move those targets first.`: those repos' Fly apps are read through that org. Name them to the person; unset or move their targets only once they agree.
- `No Fly org <org> on <server>.` or `<repo> has no <Platform> target.`: there is nothing to remove; check the name with the person.
- `name: is required`: a Vercel app needs `--name <app>`. Ask the person for a short name for it.
- `name: must be lowercase letters, digits, - or _`: a name takes lowercase letters, digits, `-` or `_`, starts with a letter or digit, and runs to 63 characters. Pick one that fits with the person.
- `name: isn't used on this platform`: a host cadre can't read takes no `--name`. Set it with `--platform <name>` alone.
- `name: <name> is already a <Platform> app of <repo>. Unset it first.`: another platform's app of the repo has that name. Pick another name with the person, or unset that app once they agree.
- `settings: <app> is already the <Platform> app of <other>, an app of <repo>. Set <other> instead, or unset it first.`: another app of the repo already points at that Fly app or Vercel project, and `cadre deploy --all` would deploy it twice. When the person meant to change `<other>`, set it with `--name <other>`; otherwise check the app with them.
- `name: <repo> has <n> <Platform> apps: <apps>. Pass --name <app>.`: `--platform` alone can't tell which app to remove. Ask the person which one, then run `cadre repo unset <repo> --name <app> --json`.
- `<repo> has no app <app>.`: there is nothing to remove; check the name with the person.
- `platform: …`: cadre refuses that platform name, or takes it only in a later release. Tell the person what it says.
- `Cadre couldn't reach Fly. Try again in a minute.`: try again in a minute.
- `No repo <repo> on <server>.`, when connecting a repo (while writing a project, see "Apps in `repos`"): cadre knows a repo once a project names it. Check the name with the person, or add the repo to a project as "Change a project" does.
- `App Store: no connected key reads <id> (asked: <key-id>)` or `Google Play: …`: no connected key or account reads that app. The parentheses say what cadre asked. Check the Apple ID or the package name with the person, or have them connect the key or account that owns it, as in step 10.
- `Your key for <url> is no longer valid. Run cadre login --url <url>.`: go back to Sign in, then retry.

## Deploy a repo

When the person asks to deploy a repo that runs on Fly or Vercel:

1. Read the repo's apps: `cadre repo show <repo> --json`. A repo with one app deploys with `cadre deploy <repo>`. On a repo with several, propose the app the deploy order puts first, as the milestone's steps or the person say, and deploy it with `cadre deploy <repo> --app <name>`. Use `--all` only when the person asks for every app. Confirm first. Once the person confirms, run the command in a checkout of that repo. A deploy can't be taken back, so never run it without the confirmation. It takes minutes: run it in the background (Bash `run_in_background`), or with a `timeout` of 600000 ms. Cadre deploys; run no `fly` or `vercel` command to deploy.
2. A mobile app deploys nothing: `cadre deploy <repo>` prints `<repo>'s releases go through the stores.` Tell the person, and point them to cadre's Apps page for each store's public build. Fly needs a clean, up-to-date `main` of that repo. Vercel deploys from any pushed commit on any branch. `--all` on Vercel apps builds them all, then promotes them together, and `--app` builds and promotes that app alone. `--all` on Fly apps deploys them one at a time, in the order Cadre's release queue lists them, and stops at the first that fails, naming each app left with the command that deploys it: relay those lines. When a check fails, cadre stops with the reason and what to do: tell the person what it printed, and stop. A repo with several apps is refused in these words instead, each with its next step:
   - `<repo> has <n> apps: <apps>. Pass --app <name> or --all.`: ask the person which app, as step 1 says, then run it again with `--app <name>`, or `--all` when they ask for every app.
   - `<repo> has <n> apps: <apps>. Pass --app <name>, in deploy order.`: its apps are on more than one platform. Ask which goes first, then run it again with `--app <name>`.
   - `<repo> has no app <app>. Its apps: <apps>.`: check the name with the person.
   - `<repo> has apps on more than one platform. Deploy each with --app <name>, in deploy order.`: `--all` can't mix platforms. Deploy each app with `--app <name>`, in deploy order, each once the person confirms, and deploy by no other way.
   - `<name> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app> --name <name>.`, or `<repo> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app>.` with one app: that app has no Fly app set. Ask the person for it, set it as the line says, carrying its config file and status URL over, then deploy again once they confirm.
   - `<repo> has no app cadre can deploy. …`: the repo has no app on Fly or Vercel that cadre tracks. Connect one as "Connect a repo to where it deploys" says.
3. On Fly, when it says `<file> isn't in this checkout.` or `Neither fly.production.toml nor fly.toml is in this checkout.`, it also says to set the right file with `cadre repo set <repo> --fly-app <app> --fly-config <file>`, with `--name <app>` when the app's name isn't its Fly app's and with `--status-url <url>` when the target has one: check the file's name with the person before setting it, carry the status URL over, since setting an app again removes a URL left out, and never deploy another way. Once the file is set, the person confirms again before `cadre deploy <repo>` runs again, with the same `--app` or `--all`.
4. On Vercel, each of these stops the deploy before any build. Tell the person what it printed:
   - `<sha7> isn't on origin. Push it, then deploy again.`: the person pushes it, or says to.
   - `<dir> isn't in this checkout.`: the checkout lacks the app's folder. Check the folder with the person; when cadre has it wrong, they set it with `cadre repo set <repo> --vercel-project <id> --name <app> --vercel-dir <folder>`, with `--status-url <url>` when the target has one, or with `--no-status-url` when it has none and should stay unmonitored: carry the status URL over, since setting an app again replaces a URL left out.
   - `<dir> has no .vercelignore. Add one that lets through only what <app>'s build reads.`: tell the person the folder has no `.vercelignore` and that one must let through only what the app's build reads. You write no file named `.vercelignore`, anywhere. You may propose its contents in chat only, saying outright that nothing was written. Deploy again once the person has added it and pushed the commit.
   - `<app> has no Vercel team in cadre. Connect it again with cadre repo set …`: go to "Connect a repo to where it deploys".
5. Before anything deploys or builds, it asks one `Deploy anyway? [y/N]` that covers every line it lists above it: the open "Before deploying" items of the PRs it would ship; a line `#<n> is Blocked: <app> should run #<m> first.` for each PR it would ship that the release queue shows Blocked, or `#<n> is Blocked: <app> should deploy first.` when that earlier step has no PR yet (the name can be another repo); and, on Vercel, a line `This commit lacks what <app> runs now (<sha7>).` for each app whose live commit this commit doesn't have. With `--app`, it lists only that app's items and Blocked PRs. You run it with no stdin, so on Vercel as on Fly nobody answers: it prints `Not deployed.`, exits 1 and builds nothing. Show the person those lines. For a Blocked PR, say which PR is Blocked and what should go first, and propose deploying that first. Under `--all`, when what should go first is an app the same run deploys first, say so: the run already deploys it first. Run `cadre deploy <repo> --yes` only once they confirm after seeing them all, with the same `--app` or `--all`. When they say an item is done, tick it as "Tick a Before deploying item" says.
6. On `fly isn't installed. …` or `fly isn't signed in. Run fly auth login.`, or `vercel isn't installed. See https://vercel.com/docs/cli.` or `vercel isn't signed in. Run vercel login.`, tell the person. Otherwise Fly exits with fly's status: when that isn't 0, tell the person what fly printed.
7. On Vercel, a failed build prints `<app>'s build failed:` and what vercel printed, then `Not deployed.` Nothing is promoted. Show the person what vercel printed. A promotion that fails prints `<app> built but didn't go live: …` and exits non-zero: name the app to the person, and relay the line saying which apps went live and which weren't promoted (`<a> went live on <sha7>. <b> weren't promoted.`). When cadre stopped while promoting an app (`cadre stopped while promoting <app>. Check Vercel to see whether it went live.`), tell the person to check Vercel for that app: it may have gone live. Running `cadre deploy <repo>` again builds and promotes them all, with the same `--app` or `--all`. On success it prints `Deployed <sha7> to <app>, <app>. Cadre shows each on its next check.`
8. Cadre reads Fly and Vercel every two minutes while it is awake, and as soon as it wakes. Two minutes after the deploy, `cadre repo show <repo> --json` shows it in the target's `last_deploy`. When it still shows the deploy before, cadre was asleep: ask again a minute later. A `commit` of `null` is "commit unknown": that deploy didn't go through `cadre deploy`.

### Tick a Before deploying item

An open item keeps its pull request Held in Cadre: it reads Held until the item is ticked or a deploy ships it. Items are ticked in GitHub, never in Cadre. `cadre deploy` names each item's pull request by its number. In that repo's checkout, `gh pr view <number>` works with the number alone; from anywhere, pass its URL or `--repo <owner>/<repo>`. When the person says an item is done, or you have just done it at their request:

1. Write `gh pr view <pr-url> --json body -q .body` to a temporary file.
2. Under `## Before deploying`, change that item's `- [ ]` to `- [x]`, and nothing else.
3. Run `gh pr edit <pr-url> --body-file <file>`. A merged pull request can be edited like any other.

Tick only what the person said is done, or what you just did at their request. When the person's words match more than one item, ask which. To undo a tick, change `- [x]` back to `- [ ]` the same way.

## Limits

| Field | Rule |
| --- | --- |
| `name` | 1–120 characters |
| `slug` | `^[a-z0-9]+(-[a-z0-9]+)*$`, up to 60 characters, unique |
| `end_goal` | 1–10 000 characters |
| `milestones` | 1–50, each `title` 1–200 characters |
| `repos` | 1–10 per milestone, no repeats, each `repo` or `repo/app`: the repo `^[a-z0-9][a-z0-9._-]{0,99}$`, the app `^[a-z0-9][a-z0-9_-]{0,62}$` |
| `number` | a milestone the project has and hasn't archived, or none for a new one |
| `spec` | optional at creation; 1–100 000 characters, not blank, UTF-8, no NUL |
| `canvas_url`, `design_url` | optional; `https://` followed by no spaces, up to 2 000 characters |
