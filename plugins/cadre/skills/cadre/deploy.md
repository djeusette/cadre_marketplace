# Deploy a repo

When the person asks to deploy a repo that runs on Fly or Vercel:

1. Read the repo's apps: `cadre repo show <repo> --json` lists them as `targets`, each with a `name` and a `platform`. Pick the command:
   - A repo with one app deploys with `cadre deploy <repo>`.
   - On a repo with several, propose the app the deploy order puts first, as the milestone's steps (its `repos`, in deploy order) or the person say, and deploy it with `cadre deploy <repo> --app <name>`. Use `--all` only when the person asks for every app.
2. Confirm first: a deploy can't be taken back.
3. Once the person confirms, run the command in a checkout of that repo. It takes minutes: run it in the background (Bash `run_in_background`), or with a `timeout` of 600000 ms.
4. Read how it ended:
   - It asked `Deploy anyway? [y/N]` and printed `Not deployed.`: follow "Deploy anyway?".
   - It stopped on a check or failed: follow "When a deploy stops" for the line it printed.
   - It deployed: Fly exits 0, and Vercel prints `Deployed <sha7> to <app>, <app>. Cadre shows each on its next check.`
5. Two minutes after the deploy, read `cadre repo show <repo> --json`. It is done when the target's `last_deploy.commit` is the commit deployed. When it is still the earlier one, cadre was asleep (it reads Fly and Vercel every two minutes while awake, and as soon as it wakes): check once more a minute later. A `commit` of `null` is "commit unknown": that deploy didn't go through `cadre deploy`.

Cadre deploys: `cadre deploy` is the one way to deploy here, whatever stops it. Never run a `fly` or `vercel` command to deploy.

## Deploy anyway?

Before anything deploys or builds, `cadre deploy` asks one `Deploy anyway? [y/N]` that covers every line it lists above it:

- the open "Before deploying" items of the PRs it would ship;
- `#<n> is Blocked: <app> should run #<m> first.` for each PR it would ship that the release queue shows Blocked, or `#<n> is Blocked: <app> should deploy first.` when that earlier step has no PR yet (the name can be another repo);
- on Vercel, `This commit lacks what <app> runs now (<sha7>).` for each app whose live commit this commit doesn't have.

With `--app`, it lists only that app's items and Blocked PRs. You run it with no stdin, so nobody answers: it prints `Not deployed.`, exits 1 and builds nothing.

1. Show the person those lines.
2. For a Blocked PR, say which PR is Blocked and what should go first, and propose deploying that first. Under `--all`, when what should go first is an app the same run deploys first, say so: the run already deploys it first.
3. When they say an item is done, tick it as "Tick a Before deploying item" says.
4. Run `cadre deploy <repo> --yes` only once they confirm after seeing them all, with the same `--app` or `--all`.

## What can deploy, and what's next

When the person asks what they can deploy, or what's next on a project, answer from cadre alone: a status question deploys nothing.

- "What can I deploy?": run `cadre status --json`. Answer from `can_deploy`: each card's `name` and the PRs it ships, in order, saying when one is `held` or `blocked_by` another. Then name `nothing_to_ship` and `not_tracked` in one line.
- "What's next on `<project>`?": the person names a project by its name, but cadre takes its slug. Take the `slug` of the entry of `cadre status --json`'s `projects` whose `name` matches, and ask which when none or several do (finished and archived projects aren't listed, so use what the person typed as the slug when it is one). Then run `cadre status <slug> --json`. Answer with `next_step.text` and its `meta`, in cadre's words. When `next_step` is null, say the project is finished or archived, as `group` says.
- "What's next?" with no project named: run `cadre status --json` and give each project's `name` with its `next_step.text`.

## Tick a Before deploying item

An open item keeps its pull request Held in Cadre: it reads Held until the item is ticked or a deploy ships it. Items are ticked in GitHub, where Cadre reads them. `cadre deploy` names each item's pull request by its number. In that repo's checkout, `gh pr view <number>` works with the number alone; from anywhere, pass its URL or `--repo <owner>/<repo>`. When the person says an item is done, or you have just done it at their request:

1. Write `gh pr view <pr-url> --json body -q .body` to a temporary file.
2. Under `## Before deploying`, change that item's `- [ ]` to `- [x]`, and nothing else.
3. Run `gh pr edit <pr-url> --body-file <file>`. A merged pull request can be edited like any other.

When the person's words match more than one item, ask which. To undo a tick, change `- [x]` back to `- [ ]` the same way.

## Open Deploy in the right folder

cadre's Deploy button opens Claude Desktop in the folder the person linked with `cadre link`. Without one, Desktop opens the folder it used last, and the prompt's last line names the repo.

Run `cadre link` in a checkout of the repo. Run it only when the person asks. Two of its answers need more than telling the person:

- `This folder isn't a checkout with an origin. Run cadre link in one.`: ask the person where their checkout of the repo is, and run it there.
- `No Skills table in <path>/AGENTS.md. Setup shows how to write one: <url>/setup?part=skills`, after `Linked …`: the link is made, and that repo's `AGENTS.md` has no Skills table. Tell the person, and offer to draft one, as "No Skills table" in [skills.md](skills.md) says.

## When a deploy stops

A fix below that runs `cadre repo set` sets the app again: read "Set an app again" in [connect.md](connect.md) first and carry every setting over. Once a fix is made, deploy again when the person confirms: `cadre deploy <repo>` with the same `--app` or `--all`, which on Vercel builds and promotes every app again.

Wrong folder:

- `This folder isn't a checkout of <owner/repo>. Run cadre deploy in one.`: the session runs outside that repo's checkout. Tell the person to start a new session and pick their checkout of it as its folder; there they run `cadre link` once, or ask you to, and the Deploy button opens in it from then on.

Which app:

- `<repo> has <n> apps: <apps>. Pass --app <name> or --all.`: ask the person which app, as step 1 of "Deploy a repo" says, then run it again with `--app <name>`, or `--all` when they ask for every app.
- `<repo> has <n> apps: <apps>. Pass --app <name>, in deploy order.`: its apps are on more than one platform. Ask which goes first, then run it again with `--app <name>`.
- `<repo> has apps on more than one platform. Deploy each with --app <name>, in deploy order.`: `--all` can't mix platforms. Deploy each app with `--app <name>`, in deploy order, each once the person confirms.

Nothing to deploy:

- `<repo>'s releases go through the stores.`: the app is a mobile app, and nothing is deployed. Tell the person, and point them to cadre's Apps page for each store's public build.
- `<repo> has no app cadre can deploy. …`: the repo has no app on Fly or Vercel that cadre tracks. Connect one as [connect.md](connect.md) says.

On Fly:

- `<name> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app> --name <name>.`, or `<repo> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app>.` with one app: that app has no Fly app set. Ask the person for it and set it as the line says.
- `<file> isn't in this checkout.` or `Neither fly.production.toml nor fly.toml is in this checkout.`: it also says to set the right file with `cadre repo set <repo> --fly-app <app> --fly-config <file>`. Check the file's name with the person before setting it.

On Vercel, before any build:

- `<sha7> isn't on origin. Push it, then deploy again.`: the person pushes it, or says to.
- `<dir> isn't in this checkout.`: the checkout lacks the app's folder. Check the folder with the person; when cadre has it wrong, they set it with `cadre repo set <repo> --vercel-project <id> --name <app> --vercel-dir <folder>`.
- `<dir> has no .vercelignore. Add one that lets through only what <app>'s build reads.`: you write no file named `.vercelignore`, anywhere. You may propose its contents in chat only, saying outright that nothing was written. The person adds it and pushes the commit.
- `<app> has no Vercel team in cadre. Connect it again with cadre repo set …`: go to [connect.md](connect.md), and set the app again as it says.
