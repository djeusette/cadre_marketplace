# Deploy a repo

When the person asks to deploy a repo that runs on Fly or Vercel:

1. Read the repo's apps: `cadre repo show <repo> --json` lists them as `targets`, each with a `name` and a `platform`. Pick the command:
   - A repo with one app deploys with `cadre deploy <repo>`.
   - On a repo with several, propose the app the deploy order puts first, as the milestone's steps (its `repos`, in deploy order) or the person say, and deploy it with `cadre deploy <repo> --app <name>`. Use `--all` only when the person asks for every app.
2. Confirm first. A deploy can't be taken back, so never run it without the confirmation.
3. Once the person confirms, run the command in a checkout of that repo. It takes minutes: run it in the background (Bash `run_in_background`), or with a `timeout` of 600000 ms.
4. Read how it ended:
   - It asked `Deploy anyway? [y/N]` and printed `Not deployed.`: follow "Deploy anyway?".
   - It stopped on a check or failed: cadre stops with the reason and what to do. Tell the person what it printed, and stop, unless "When a deploy stops" gives that line a next step.
   - It deployed: Fly exits 0, and Vercel prints `Deployed <sha7> to <app>, <app>. Cadre shows each on its next check.`
5. Cadre reads Fly and Vercel every two minutes while it is awake, and as soon as it wakes. Two minutes after the deploy, `cadre repo show <repo> --json` shows it in the target's `last_deploy`. When it still shows the deploy before, cadre was asleep: ask again a minute later. A `commit` of `null` is "commit unknown": that deploy didn't go through `cadre deploy`.

Cadre deploys: `cadre deploy` is the one way to deploy here, whatever stops it. Never run a `fly` or `vercel` command to deploy.

## Deploy anyway?

Before anything deploys or builds, `cadre deploy` asks one `Deploy anyway? [y/N]` that covers every line it lists above it:

- the open "Before deploying" items of the PRs it would ship;
- `#<n> is Blocked: <app> should run #<m> first.` for each PR it would ship that the release queue shows Blocked, or `#<n> is Blocked: <app> should deploy first.` when that earlier step has no PR yet (the name can be another repo);
- on Vercel, `This commit lacks what <app> runs now (<sha7>).` for each app whose live commit this commit doesn't have.

With `--app`, it lists only that app's items and Blocked PRs. You run it with no stdin, so on Vercel as on Fly nobody answers: it prints `Not deployed.`, exits 1 and builds nothing.

1. Show the person those lines.
2. For a Blocked PR, say which PR is Blocked and what should go first, and propose deploying that first. Under `--all`, when what should go first is an app the same run deploys first, say so: the run already deploys it first.
3. When they say an item is done, tick it as "Tick a Before deploying item" says.
4. Run `cadre deploy <repo> --yes` only once they confirm after seeing them all, with the same `--app` or `--all`.

## Tick a Before deploying item

An open item keeps its pull request Held in Cadre: it reads Held until the item is ticked or a deploy ships it. Items are ticked in GitHub, where Cadre reads them. `cadre deploy` names each item's pull request by its number. In that repo's checkout, `gh pr view <number>` works with the number alone; from anywhere, pass its URL or `--repo <owner>/<repo>`. When the person says an item is done, or you have just done it at their request:

1. Write `gh pr view <pr-url> --json body -q .body` to a temporary file.
2. Under `## Before deploying`, change that item's `- [ ]` to `- [x]`, and nothing else.
3. Run `gh pr edit <pr-url> --body-file <file>`. A merged pull request can be edited like any other.

Tick only what the person said is done, or what you just did at their request. When the person's words match more than one item, ask which. To undo a tick, change `- [x]` back to `- [ ]` the same way.

## What a deploy does

- **Fly** needs a clean, up-to-date `main` of that repo. `--all` on Fly apps deploys them one at a time, in the order Cadre's release queue lists them, and stops at the first that fails, naming each app left with the command that deploys it: relay those lines.
- **Vercel** deploys from any pushed commit on any branch. `--all` on Vercel apps builds them all, then promotes them together, and `--app` builds and promotes that app alone.

## When a deploy stops

Which app:

- `<repo> has <n> apps: <apps>. Pass --app <name> or --all.`: ask the person which app, as step 1 of "Deploy a repo" says, then run it again with `--app <name>`, or `--all` when they ask for every app.
- `<repo> has <n> apps: <apps>. Pass --app <name>, in deploy order.`: its apps are on more than one platform. Ask which goes first, then run it again with `--app <name>`.
- `<repo> has apps on more than one platform. Deploy each with --app <name>, in deploy order.`: `--all` can't mix platforms. Deploy each app with `--app <name>`, in deploy order, each once the person confirms.
- `<repo> has no app <app>. Its apps: <apps>.`: check the name with the person.

Nothing to deploy:

- `<repo>'s releases go through the stores.`: the app is a mobile app, and nothing is deployed. Tell the person, and point them to cadre's Apps page for each store's public build.
- `<repo> has no app cadre can deploy. …`: the repo has no app on Fly or Vercel that cadre tracks. Connect one as [connect.md](connect.md) says.

On Fly:

- `<name> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app> --name <name>.`, or `<repo> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app>.` with one app: that app has no Fly app set. Ask the person for it and set it as the line says. That sets the app again, so read "Set an app again" in [connect.md](connect.md) first and carry its config file and status URL over. Then deploy again once they confirm.
- `<file> isn't in this checkout.` or `Neither fly.production.toml nor fly.toml is in this checkout.`: it also says to set the right file with `cadre repo set <repo> --fly-app <app> --fly-config <file>`. Check the file's name with the person before setting it. That sets the app again, so read "Set an app again" in [connect.md](connect.md) first and carry its name and status URL over. Once the file is set, the person confirms again before `cadre deploy <repo>` runs again, with the same `--app` or `--all`.
- `fly isn't installed. …` or `fly isn't signed in. Run fly auth login.`: tell the person.
- Any other failure is fly's own, as cadre exits with fly's status: when that isn't 0, tell the person what fly printed.

On Vercel, each of these stops the deploy before any build. Tell the person what it printed:

- `<sha7> isn't on origin. Push it, then deploy again.`: the person pushes it, or says to.
- `<dir> isn't in this checkout.`: the checkout lacks the app's folder. Check the folder with the person; when cadre has it wrong, they set it with `cadre repo set <repo> --vercel-project <id> --name <app> --vercel-dir <folder>`. That sets the app again, so read "Set an app again" in [connect.md](connect.md) first and carry its status URL over, or pass `--no-status-url` when it has none and should stay unmonitored.
- `<dir> has no .vercelignore. Add one that lets through only what <app>'s build reads.`: tell the person the folder has no `.vercelignore` and that one must let through only what the app's build reads. You write no file named `.vercelignore`, anywhere. You may propose its contents in chat only, saying outright that nothing was written. Deploy again once the person has added it and pushed the commit.
- `<app> has no Vercel team in cadre. Connect it again with cadre repo set …`: go to [connect.md](connect.md), and set the app again as it says.
- `vercel isn't installed. See https://vercel.com/docs/cli.` or `vercel isn't signed in. Run vercel login.`: tell the person.

On Vercel, once it builds:

- `<app>'s build failed:` and what vercel printed, then `Not deployed.`: nothing is promoted. Show the person what vercel printed.
- `<app> built but didn't go live: …`, with a non-zero exit: a promotion failed. Name the app to the person, and relay the line saying which apps went live and which weren't promoted (`<a> went live on <sha7>. <b> weren't promoted.`).
- `cadre stopped while promoting <app>. Check Vercel to see whether it went live.`: tell the person to check Vercel for that app: it may have gone live.

Running `cadre deploy <repo>` again builds and promotes them all, with the same `--app` or `--all`.
