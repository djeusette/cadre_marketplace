# Milestones and their pull requests

## Start a milestone

When the person asks to "start milestone `<slug>/<n>`", or to start work on a milestone in Cadre:

1. Pull the project into a temporary `.json` file: `cadre project pull <slug> -o <tmp>.json --json`. The milestone's `repos` are its steps in deploy order: a repo/app entry is its repo, one step of it per app. Then pull its spec into a temporary `.md` file: `cadre spec pull <slug>/<n> -o <tmp>.md --json`. On `<slug>/<n> has no spec yet.`, write its spec first, as "Update a milestone's spec" in [project.md](project.md) says, then pull it again.
2. Run `gh repo view --json name -q .name`. When this repo is one of the milestone's repos, work on this repo's part. Otherwise, name the milestone's repos to the person, in deploy order, and stop: the milestone starts in the first step with no pull request yet, found as "The first step with no pull request" says. Each other repo of the milestone is started the same way, in its own session in that repo.
3. When `git branch --show-current` prints the repo's default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), switch to the milestone's branch: `git switch -c <slug>-<n>`, or `git switch <slug>-<n>` when it already exists. When the pull request is for one app of several, the branch is `<slug>-<n>-<app>` instead: `git switch -c <slug>-<n>-<app>`, or `git switch <slug>-<n>-<app>` when it already exists. The plan and its pull request start from that branch, so the record lands on it with them and the default branch stays as it was.
4. Copy the spec into this repo's `docs/superpowers/specs/<slug>-<n>.md` as a record, creating the folder when it is missing, and commit only that file: `git add <path>`, then `git commit -m "docs: spec of <slug>/<n>" -- <path>`. When `<path>` already holds this text, as when a milestone is started again, skip the commit: there is nothing to commit. Cadre's copy stays the original: cadre reads only its own.
5. Plan this repo's part with `superpowers:writing-plans`, giving it the spec copy's path and these rules on top:
   - plan only this repo's part of milestone `<slug>/<n>`;
   - one plan and one pull request per repo, or per app when the milestone's steps name that repo's apps and the work splits that way;
   - the two rules of "The pull request's description", given in full: its `Cadre:` line and its `## Before deploying` section;
   - the plan's header says it is tracked in Cadre, on the line under its title, so whoever executes it uses this skill:

     ```markdown
     > **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n>`.
     ```

     When the plan is for one app, the header's last line names it:

     ```markdown
     > **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n> <app>`.
     ```
6. Execute the plan as `superpowers:writing-plans` offers.

## Track a milestone's implementation

A spec or plan tracked in Cadre says so on the line under its title. When you implement one, for example while executing such a plan:

- Its pull request's description is as "The pull request's description" says. When the pull request is already open without its `Cadre:` line, add it: write `gh pr view <pr-url> --json body -q .body` to a temporary file, add the line, then run `gh pr edit <pr-url> --body-file <file>`.
- A feature spec names only its project, `<slug>`: its increment `<i>` is milestone `<slug>/<i>`. Start it as "Start a milestone" says, so its plan says it is tracked too.

## Link a pull request by hand

A pull request opened without the `Cadre:` line, or before the cadre GitHub App was installed, is linked by hand:

- `cadre pr link <pr-url> <slug>/<n> --json` links it. Cadre reads the pull request from GitHub then.
- `cadre pr link <pr-url> <slug>/<n> --app <app> --json` names the app the pull request is for. The JSON body then has an `app` field, null when none.
- `cadre pr link <pr-url> --none --json` unlinks it.

Report the `project_url` field of the JSON body. A `Cadre:` line in its description wins at its next sync, so edit the line rather than fight it.

## The pull request's description

The description of a milestone's pull request holds:

- **Its `Cadre:` line.** A line of its own that reads exactly `Cadre: <slug>/<n>`, or `Cadre: <slug>/<n> <app>` for a pull request for one app, links the pull request to the milestone in Cadre. The app is its name in Cadre, as `cadre repo show` lists it (a target's `name`): lowercase letters, digits, `-` or `_`. A line whose app isn't such a name links nothing.
- **Its `## Before deploying` section.** When the change needs something before it ships, such as a new env var or secret, another repo deployed first, or a manual step, the description lists it under a heading line `## Before deploying`, as a task list with one `- [ ]` item for each. The person ticks an item in GitHub once it's done. A change that needs nothing has no section.

## The first step with no pull request

A milestone starts at the first of its steps that no pull request holds. To find it, run in each repo of the milestone, in deploy order:

```bash
gh pr list --repo <owner>/<repo> --state all --search '"Cadre: <slug>/<n>" in:body' --json number,state,body
```

`<owner>` is the GitHub owner of this checkout, `gh repo view --json owner -q .owner.login`: Cadre's repos all live under one org, so it serves the milestone's other repos too.

- The search is a text search, so `"Cadre: <slug>/2"` also matches `<slug>/20`: read each body's `Cadre:` line and keep only the pull requests whose line names exactly `<slug>/<n>`, optionally followed by an app.
- A pull request whose line names an app holds that app's step. One whose line names no app holds every step of its repo. A closed, unmerged pull request holds nothing.
- When the first step none holds is unclear, ask the person.

## When `cadre` refuses

- `No project <slug> on <server>.` or `No milestone <slug>/<n> on <server>.`: check the slug and number with the person.
- `GitHub has no pull request at <url>.`: check the URL with the person.
- `GitHub isn't connected on <server> yet. …`: tell the person, and stop.
- `app: must be lowercase letters, digits, - or _`: check the app's name with the person. It is the app's name in Cadre, as `cadre repo show` lists it.
- `url: is in a repo no project names`: the repo needs to be in a project first, as "Change a project" in [project.md](project.md) adds it.
