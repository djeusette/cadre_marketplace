# Projects and their specs

## Create a project

1. Get the feature's spec, one with an `## End goal` and an `## Increments` section: the spec the person names, or a likely one in `docs/superpowers/specs/` once you ask and the person confirms it is this feature. When there is none, or the spec the person names lacks either section, load the `cadre:brainstorming` skill and brainstorm the feature with the person as it says, from that spec when there is one. This step is done when you hold that spec.
2. Build the project from the spec:
   - `name`: the spec's title without ` — design`.
   - `slug`: the name in kebab case, lowercase letters and digits only.
   - `end_goal`: the text of the End goal section.
   - `milestones`: one per `### Increment`, in spec order, its `title` the increment's title and its `repos` as "A milestone's `repos`" says.
3. Check that the feature spec says it is tracked in Cadre, on the line under its title, so whoever implements it uses the `cadre:cadre` skill:

   ```markdown
   > Tracked in Cadre as `<slug>`. Implement each increment with the `cadre:cadre` skill ("start milestone <slug>/<i>"), which plans it and links its pull request to its milestone.
   ```

   When a spec the person named lacks the line, add it and leave the commit to them.
4. Draw the project's canvas as [canvas.md](canvas.md) says, and keep the canvas link and each milestone's design link, built as "Link a milestone to its design" says. When no milestone has a screen, the project has no canvas: go to step 5.
5. Write one spec per milestone, as "Write a milestone's spec" says.
6. Play every milestone back one last time, as it will be registered: its title, its repos in deploy order, its consumers, what it delivers and its design link, then the files each app's styles were read from. When this run created the canvas, ask the person to confirm the canvas is shared with the team: you can't change its sharing, and every link must open for the team. Register nothing until the person approves them and, for a new canvas, confirms it is shared. Fix what they correct first. When a correction changes the feature spec, update the spec. When the brainstorm wrote it, commit only the spec file, with the `git` commands "The handoff" in [the brainstorming skill](../brainstorming/SKILL.md) gives; when the person named it, leave the commit to them.
7. Add them to the project: `canvas_url` is the canvas link and, per milestone, `spec` is its markdown and `design_url` its design link.
8. Write the JSON to a temporary file and run `cadre project create <file> --json`. On a `422`, fix it as "When `cadre` refuses" says.
9. Report the `url` field of the JSON body the command printed. When the session had no Artifact tool, say the project has no design yet.

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
      "design_url": "https://claude.ai/artifact/…#artboard-…"
    },
    {
      "title": "Members choose when they are reminded",
      "repos": ["shop-api", "shop-mobile"],
      "spec": "# Wish reminders 2: Members choose when they are reminded\n\n...",
      "design_url": "https://claude.ai/artifact/…#artboard-…"
    }
  ],
  "canvas_url": "https://claude.ai/artifact/…#page-…"
}
```

## Write a milestone's spec

A milestone's spec is markdown that starts with `# <name> <n>: <title>`, for example `# Wish reminders 2: Members choose when they are reminded`, and the line under it says it is tracked in Cadre:

```markdown
> Tracked in Cadre as `<slug>/<n>`. Implement it with the `cadre:cadre` skill ("start milestone <slug>/<n>"), which plans it and links its pull request to the milestone.
```

It holds only this milestone's part of the feature spec: that increment's Delivers, Deployable alone, Consumers and Code files, and whatever its other sections say about this milestone: its screens, data, API, rules and errors.

## Link a milestone to its design

A milestone's design link opens the canvas on that milestone's designs, and the project's canvas link opens its review page. Read a board's key in `boards` and a page's `id` in `pages` of the canvas's `project/canvas.json`, then build each link with [design_link.rb](design_link.rb), in project.md's folder:

```bash
ruby <project.md's folder>/design_link.rb <canvas_url> --board <file>
ruby <project.md's folder>/design_link.rb <canvas_url> --page review
```

- A milestone's `design_url` links the first board of its first row, `--board <file>`: its row on the earliest part page in `pages`, and the row's first 1440 board, or its phone board for a screen only the mobile app has.
- The project's `canvas_url` links the review page: `--page review`.
- When `pages` has no `review` page, the canvas predates [canvas.md](canvas.md): a milestone links its own page with `--page <id>`, and the canvas link stays as it is.
- The link holds a hash of the page's `id` or the board's file name. When one of them changes, the link opens the canvas's default view, so build it again.
- When `ruby` is missing, ask the person to select the board, or open the page, in the canvas and send you what their address bar shows: it is the same link.

## Show a milestone's spec

Run `cadre spec pull <project>/<n>` and show the person what it prints.

## Update a milestone's spec

When the person asks to "update the spec of `<project>/<n>`", for example because a card in Cadre says "No spec or designs yet", or because an earlier milestone taught something:

1. Pull the spec into a temporary `.md` file: `cadre spec pull <project>/<n> -o <file> --json`. Keep the JSON's `version` and `updated_by`.
2. On `<project>/<n> has no spec yet.`, nothing is written: write the milestone's spec into the file as "Write a milestone's spec" says, then push it without a base, `cadre spec push <project>/<n> <file> --json`, and go to step 5.
3. Otherwise edit the pulled file with the person: what they asked for, and what earlier milestones taught. Keep its title line and its sections. A push changes only the spec; a design link changes as "Change a project" says.
4. Push it with the version you pulled as its base: `cadre spec push <project>/<n> <file> --base <version> --json`.
5. Report the `url` field of the JSON body and the change in one or two lines. The milestone's card in Cadre now offers the text the push replaced as its previous version.

For a further change after a push, pull again first: each push needs the newest `version` as its base.

## Change a project

When the person asks to change a project in Cadre, for example to rename it, reorder or rename its milestones, change their repos, design links or deploy order, add a milestone, or drop the project:

1. Pull the project into a temporary `.json` file: `cadre project pull <slug> -o <file> --json`. Keep the JSON's `version`. When `archived` is true, ask the person whether to bring the project back first. When they agree, run `cadre project unarchive <slug>` and continue with the same file: unarchiving doesn't change the version.
2. Edit the file with the person:
   - the name, end goal, home repo (one of the milestones' repos) and canvas link;
   - reorder milestones by moving their entries;
   - rename them, and change their design links, repos and deploy order;
   - name their apps, as "A milestone's `repos`" says;
   - add one as an entry with no `number`, no `spec` and no `design_url`: Cadre numbers it, and its spec and designs come after the update (step 5).

   Keep every `number`, the `slug`, the `version` and the canvas link exactly as pulled. When the person asks to change the canvas link, tell them it clears its design approvals in Cadre: any change to its text does. A milestone that has a `number` takes its spec through "Update a milestone's spec" only: leave `spec` out of its entry.
3. Leaving a milestone out archives it, and its number is retired for good: say so, and leave one out only once the person agrees.
4. Play the change back in a few lines, and apply it once the person approves: `cadre project update <file> --json`. Report the new `version` and the `url`.
5. For each milestone you added, once the update has succeeded:
   - Pull the project again: `cadre project pull <slug> -o <file> --json`. The new milestone is the entry whose `number` was not in the file you sent. Its number follows the highest one the project ever used, archived milestones included, so you could not know it before.
   - Write its spec as "Write a milestone's spec" says, with that number, and push it without a base, as it has no spec yet: `cadre spec push <slug>/<n> <spec-file> --json`.
   - When the milestone has a screen, draw its designs as "Add a milestone to a canvas" in [canvas.md](canvas.md) says. Once they exist, pull the project again, set that entry's `design_url` to its design link, built as "Link a milestone to its design" says, and run `cadre project update <file> --json`. When the project has no canvas yet, follow "Draw a canvas for a project without one" instead: it sets every link.
   - Report the new number to the person, with the `url`.

### Drop a project

To drop a project ("drop gift-wrapping"): confirm with the person, run `cadre project archive <slug>`, and say it hides the project from the Overview, and that `cadre project unarchive <slug>` brings it back.

### Draw a canvas for a project without one

When the person asks for the designs of a project that has no `canvas_url` and a milestone with a screen:

1. Pull the project into a temporary `.json` file, `cadre project pull <slug> -o <file> --json`, and each milestone's spec with `cadre spec pull <slug>/<n>`.
2. Draw the canvas from those specs, as [canvas.md](canvas.md) says.
3. Ask the person to confirm the canvas is shared with the team: you can't change its sharing.
4. Once the person confirms it is shared, set `canvas_url` and each milestone's `design_url` as "Link a milestone to its design" says, play the change back with the files each app's styles were read from, and apply it once the person approves: `cadre project update <file> --json`. Report the `url`.

## A milestone's `repos`

A milestone's `repos` are the repositories its increment changes, in deploy order: the order the spec's Consumers and deploy-order lines give, the repo that must deploy first listed first. Consumers can say "none".

- Repo names are bare, `shop-api` and not `acme/shop-api`, and match the limits below.
- Take a repo name only from the spec or from the person, and ask when unsure. A file path is not a repo name.
- The current repository (`gh repo view --json name -q .name`) is a repo of every increment whose Code files live in it.

A step can name an app, as `repo/app`. Read `cadre repo show <repo> --json` for each repo: its `targets` are the repo's apps, each with a `name`.

- A repo with one app stays a bare repo, unless the milestone also expects an app of it that isn't connected yet.
- A repo with several apps, or a one-app repo with that app still to connect, gets one `repo/app` entry per app the milestone expects, in deploy order, the API before the frontend, for example `"repos": ["kinfield/kinfield", "kinfield/kinfield-family"]`.
- When the spec doesn't say which apps, ask the person.
- A milestone lists a repo one way only: bare, or by its apps.
- `No repo <repo> on <server>.` means Cadre doesn't know the repo yet. It has no app there, so it stays a bare `repo` unless the spec names its apps. That answer is expected: carry on without a question to the person.

## When `cadre` refuses

- On a `422`, `project create` prints one `<path>: <message>` line per error, for example `milestones.1.repos.0: …`, and `project update` prints the same kind of line, such as `milestones.<i>.number: …`. Fix the fields those paths name, then run the command again. Error paths are 0-based positions in the JSON arrays: `milestones.1.repos.0` is the first repo of the second milestone, while milestone numbers shown elsewhere start at 1. When you change the `slug`, change it on the spec's tracking line too.
- `spec: …`: the file broke a limit below: fix it and push again.
- `No project <slug> on <server>.` or `No milestone <project>/<n> on <server>.`: check the project's slug and the milestone's number with the person.
- `The spec of <project>/<n> changed since you pulled it. Pull it again.`: someone pushed after your pull. Pull again, tell the person who (`updated_by`), apply the same edit to the new text, and push with the new `version`.
- `<slug> changed since you pulled it (version <n>, now <m>). Pull it again.`: pull again, redo the edit on the new file, play it back, and update.
- `<slug> is archived. Run cadre project unarchive <slug> first.`: ask the person whether to bring the project back. When they agree, run `cadre project unarchive <slug>` and update again with the same file.

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
