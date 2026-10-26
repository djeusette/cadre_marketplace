---
name: cadre
description: Use when the person asks to register, create or track a project, feature or milestones in Cadre, to read, write or update a milestone's spec in Cadre ("update the spec of <project>/<n>"), or to sign in to Cadre.
---

# Cadre

Cadre shows where every milestone of a feature stands, on every repo, in deploy order. You register a project there from a colette spec with the `cadre` CLI: one milestone per spec increment, each with the repos it touches, its own spec and a link to its designs.

## Before you start

1. Check that `colette:brainstorming` is among your available skills. When it is missing, say the `colette` plugin must be installed and enabled, and stop.
2. Run `gh auth status`. When it fails, tell the person to run `gh auth login`, and stop. The CLI is downloaded with `gh`.

## Install or update the CLI

Run `cadre version`.

- When the command is missing, run:

  ```bash
  mkdir -p ~/.local/bin
  gh release download -R djeusette/cadre_cli --pattern "cadre_$(uname -s)_$(uname -m).tar.gz" -O - | tar -xz -C ~/.local/bin cadre
  ```

  Then run `cadre version` again. When the command is still missing, `~/.local/bin` is not on the person's `PATH`: tell them to add it, and stop.
- When it reports a version below `0.5.0`, run `cadre upgrade`. It replaces that `cadre` with the latest release and prints `Upgraded cadre from <old> to <new>.` When it fails, tell the person what it printed, and stop.

## Sign in

Run `cadre whoami --json`. It succeeds when the exit code is 0 and the JSON holds an `email`.

- `Not signed in. Run cadre login --url <url>.`: ask the person for their Cadre URL, the address they open Cadre at in their browser, such as `https://cadre.example.com`. Never guess it. Then run `cadre login --url <url>` with it. It waits up to 10 minutes for the person to click **Allow**, but the Bash tool stops a command after 2 minutes by default and shows no output until the command exits. So run it in the background (Bash `run_in_background`), or with a `timeout` of 600000 ms. Read its first two output lines, `Opening <uri> in your browser.` and `Check that the page shows this code: <code>`, and tell the person the URL and the code: they check that the page shows that code, then click **Allow**. Then wait for the command to exit and read `Signed in as <email>.`
- `Your key for <url> is no longer valid. Run cadre login --url <url>.`: run `cadre login --url <url>` with the URL the message names, as above.
- `The code expired. Run cadre login --url <url> again.`: run it again with the same URL.
- `--url must be an http:// or https:// URL with a host, …`: the URL is not a full address; ask the person for it again.

The person never types or copies a key.

## Create a project

1. Find the spec of the feature in `docs/superpowers/specs/`. When there is none, run `colette:brainstorming` first and come back with its spec.
2. Build the project from the spec:
   - `name`: the spec's title without ` — design`.
   - `slug`: the name in kebab case, lowercase letters and digits only.
   - `end_goal`: the text of the End goal section.
   - `milestones`: one per `### Increment`, in spec order, its `title` the increment's title. Its `repos` are the repositories the increment changes, in deploy order: the order the spec's Consumers and deploy-order lines give, the repo that must deploy first listed first.
   Repo names are bare, `colette-api` and not `colette-club/colette-api`, and match the limits below. The current repository (`gh repo view --json name -q .name`) is a repo of every increment whose Code files live in it. A file path is never a repo. Consumers can say "none".
3. Play the repos of each milestone back, and ask the person once to confirm them. Take a repo name only from the spec or from the person, and ask when unsure.
4. Design every milestone: create one Claude Design canvas for the project, with one page per milestone. A milestone without a screen gets a diagram as its page instead: its data flow or its API contract. Keep the canvas link and each page's link.
5. Write one spec per milestone, as the next section describes.
6. Add them to the project: `canvas_url` is the canvas link and, per milestone, `spec` is its markdown and `design_url` the link to its page in the canvas, or the canvas link when there is no page link.
7. Write the JSON to a temporary file and run `cadre project create <file> --json`.
   When it prints `Your key for <url> is no longer valid. Run cadre login --url <url>.`, go back to Sign in, then run it again.
8. On a `422`, the CLI prints one `<path>: <message>` line per error, for example `milestones.1.repos.0: …`. Fix the fields those paths name, then run the command again. Error paths are 0-based positions in the JSON arrays: `milestones.1.repos.0` is the first repo of the second milestone, while milestone numbers shown elsewhere start at 1.
9. Report the `url` field of the JSON body the command printed, and remind the person to share the canvas with the team: you can't change its sharing.

```json
{
  "name": "Wish reminders",
  "slug": "wish-reminders",
  "end_goal": "Members get a reminder before a wish expires.",
  "milestones": [
    {
      "title": "The API stores a reminder date",
      "repos": ["colette-api"],
      "spec": "# Wish reminders 1: The API stores a reminder date\n\n...",
      "design_url": "https://claude.ai/design/p/…?page=1"
    },
    {
      "title": "The app lets members set it",
      "repos": ["colette-api", "club-mobile"],
      "spec": "# Wish reminders 2: The app lets members set it\n\n...",
      "design_url": "https://claude.ai/design/p/…?page=2"
    }
  ],
  "canvas_url": "https://claude.ai/design/p/…"
}
```

## Write a milestone's spec

A milestone's spec is markdown that starts with `# <name> <n>: <title>`, for example `# Wish reminders 2: The app lets members set it`. Then it gives that increment's Delivers, Deployable alone, Consumers and Code files from the feature spec, and whatever the feature spec's other sections say about this milestone: its screens, data, API, rules and errors. It has no `## Increments` section and no `- [ ] Not shipped` line.

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

## Limits

| Field | Rule |
| --- | --- |
| `name` | 1–120 characters |
| `slug` | `^[a-z0-9]+(-[a-z0-9]+)*$`, up to 60 characters, unique |
| `end_goal` | 1–10 000 characters |
| `milestones` | 1–50, each `title` 1–200 characters |
| `repos` | 1–10 per milestone, no repeats, each `^[a-z0-9][a-z0-9._-]{0,99}$` |
| `spec` | optional at creation; 1–100 000 characters, not blank, UTF-8, no NUL |
| `canvas_url`, `design_url` | optional; `https://` followed by no spaces, up to 2 000 characters |
