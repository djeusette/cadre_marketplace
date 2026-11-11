# Projects and their specs

## Create a project

1. Get the feature's spec:
   - When the person names a spec that already has an `## End goal` and an `## Increments` section, build from it, without the questions.
   - When a spec in `docs/superpowers/specs/` might be this feature, ask the person whether it is: a spec is this feature's only once the person says so.
   - Otherwise, read [brainstorm.md](brainstorm.md) and brainstorm the feature with the person as it says. It ends with the spec committed.
2. Build the project from the spec:
   - `name`: the spec's title without ` — design`.
   - `slug`: the name in kebab case, lowercase letters and digits only.
   - `end_goal`: the text of the End goal section.
   - `milestones`: one per `### Increment`, in spec order, its `title` the increment's title and its `repos` as "A milestone's `repos`" says.
3. Check that the feature spec says it is tracked in Cadre, on the line under its title, so whoever implements it uses this skill:

   ```markdown
   > Tracked in Cadre as `<slug>`. Implement each increment with the `cadre:cadre` skill ("start milestone <slug>/<i>"), which plans it and links its pull request to its milestone.
   ```

   Add the line when the spec lacks it, and commit it as step 6 commits a correction.
4. Design every milestone: create one Claude Design canvas for the project, with one page per milestone. A milestone without a screen gets a diagram as its page instead: its data flow or its API contract. Keep the canvas link and each milestone's design link, built as "Link a milestone to its design" says.
5. Write one spec per milestone, as "Write a milestone's spec" says.
6. Play every milestone back one last time, as it will be registered: its title, its repos in deploy order, its consumers, what it delivers and its design link. Register nothing until the person approves them. Fix what they correct first. When a correction changes the feature spec, update the spec, then:
   - if the brainstorm committed it, commit only that file again with `git commit -m "docs: <feature> design" -- <path>`. Pushing stays with the person: never push;
   - if the person named it, leave the commit to them.
7. Add them to the project: `canvas_url` is the canvas link and, per milestone, `spec` is its markdown and `design_url` its design link.
8. Write the JSON to a temporary file and run `cadre project create <file> --json`. On a `422`, fix it as "When `cadre` refuses" says, then run the command again.
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
2. On `<project>/<n> has no spec yet.`, nothing is written: write the milestone's spec into the file as "Write a milestone's spec" says, then push it without a base, `cadre spec push <project>/<n> <file> --json`, and go to step 5.
3. Otherwise edit the pulled file with the person: what they asked for, and what earlier milestones taught. Keep its title line and its sections. A push changes only the spec: a design link is set when the project is created.
4. Push it with the version you pulled as its base: `cadre spec push <project>/<n> <file> --base <version> --json`. Cadre keeps the file exactly as written, as the milestone's newest spec.
5. Report the `url` field of the JSON body and the change in one or two lines. The milestone's card in Cadre now offers the text the push replaced as its previous version.

For a further change after a push, pull again first: each push needs the newest `version` as its base.

To show the person a spec, run `cadre spec pull <project>/<n>` and show what it prints.

## Change a project

When the person asks to change a project in Cadre, for example to rename it, reorder or rename its milestones, change their repos, design links or deploy order, add a milestone, or drop the project:

1. Pull the project into a temporary `.json` file: `cadre project pull <slug> -o <file> --json`. Keep the JSON's `version`. When `archived` is true, ask the person whether to bring the project back first. When they agree, run `cadre project unarchive <slug>` and continue with the same file: unarchiving doesn't change the version.
2. Edit the file with the person:
   - the name, end goal, home repo (one of the milestones' repos) and canvas link;
   - reorder milestones by moving their entries;
   - rename them, and change their design links, repos and deploy order;
   - name their apps, as "A milestone's `repos`" says;
   - add one as an entry with no `number`, no `spec` and no `design_url`: Cadre numbers it, and its spec and page come after the update (step 5).

   Keep every `number`, the `slug` and the `version` as pulled. A milestone that has a `number` takes its spec through "Update a milestone's spec" only: leave `spec` out of its entry.
3. Leaving a milestone out archives it, and its number is retired for good: say so, and leave one out only once the person agrees.
4. Play the change back in a few lines, and apply it once the person approves: `cadre project update <file> --json`. Report the new `version` and the `url`.
5. For each milestone you added, once the update has succeeded:
   - Pull the project again: `cadre project pull <slug> -o <file> --json`. The new milestone is the entry whose `number` was not in the file you sent. Its number follows the highest one the project ever used, archived milestones included, so you could not know it before.
   - Write its spec as "Write a milestone's spec" says, with that number, and push it without a base, as it has no spec yet: `cadre spec push <slug>/<n> <spec-file> --json`.
   - Draw its page in the project's design canvas, as "Create a project" does for every milestone, then put its design link, built as "Link a milestone to its design" says, in the pulled file as its `design_url`. Pull once more for the new `version`, edit that one entry, and run `cadre project update <file> --json`.
   - Report the new number to the person, with the `url`.

### Drop a project

To drop a project ("drop gift-wrapping"): confirm with the person, run `cadre project archive <slug>`, and say it hides the project from the Overview, and that `cadre project unarchive <slug>` brings it back.

## A milestone's `repos`

A milestone's `repos` are the repositories its increment changes, in deploy order: the order the spec's Consumers and deploy-order lines give, the repo that must deploy first listed first. Consumers can say "none".

- Repo names are bare, `shop-api` and not `acme/shop-api`, and match the limits below.
- Take a repo name only from the spec or from the person, and ask when unsure. A file path is not a repo name.
- The current repository (`gh repo view --json name -q .name`) is a repo of every increment whose Code files live in it.

A step can name an app, as `repo/app`. Read `cadre repo show <repo> --json` for each repo: its `targets` are the repo's apps, each with a `name`.

- A repo with one app stays a bare repo, unless the milestone also expects an app of it that isn't connected yet: then name each app the milestone expects as `repo/app`, the API before the frontend.
- A repo with several apps gets one `repo/app` entry per app the milestone expects, in deploy order, the API before the frontend, for example `"repos": ["kinfield/kinfield", "kinfield/kinfield-family"]`.
- When the spec doesn't say which apps, ask the person. An app that isn't connected yet can be named.
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
