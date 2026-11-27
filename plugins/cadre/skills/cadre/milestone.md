# Milestones and their pull requests

## Start a milestone

When the person asks to "start milestone `<slug>/<n>`", or to start work on a milestone in Cadre:

1. Pull the project into a temporary `.json` file: `cadre project pull <slug> -o <tmp>.json --json`. The milestone's `repos` are its steps in deploy order: a repo/app entry is its repo, one step of it per app. Then pull its spec into a temporary `.md` file: `cadre spec pull <slug>/<n> -o <tmp>.md --json`. On `<slug>/<n> has no spec yet.`, write its spec first, as "Update a milestone's spec" in [project.md](project.md) says, then pull it again.
2. Find this repo's part. Run `gh repo view --json name -q .name`:
   - When this repo is not one of the milestone's repos, name the milestone's repos to the person in deploy order, name the step it starts at, the first step with no pull request found as "The first step with no pull request" says, and stop. Each repo of the milestone is started the same way, in its own session in that repo.
   - When it is, this repo's part is its steps. When those steps name this repo's apps and the work splits by app, the pull request is for one app: the app the person named, otherwise the first of this repo's app steps with no pull request, found as "The first step with no pull request" says. Otherwise one pull request covers every step of this repo, and its `Cadre:` line names no app.

   This step is done when you know this repo's part and, for one app's pull request, its app.
3. Work on the milestone's branch, `<branch>`: `<slug>-<n>`, or `<slug>-<n>-<app>` for one app's pull request, in a worktree. Take the first case that fits:
   - When `git worktree list` shows a worktree on `<branch>`, as when a milestone is started again, move into it.
   - When `<branch>` exists with no worktree, add one for it, since a native tool makes only new branches: `git worktree add .worktrees/<branch> <branch>`, with `.worktrees/` git-ignored as `superpowers:using-git-worktrees` says. Then move into it.
   - Otherwise set one up with `superpowers:using-git-worktrees`, with these rules on top. The person has agreed to a worktree: make one without asking. A new worktree is named `<branch>`, starts from the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`) and sits in a hidden folder of the main checkout: the native tool's own, such as `.claude/worktrees/<branch>`, otherwise `.worktrees/<branch>`.

   In the worktree, when `git branch --show-current` prints another branch, as in a worktree the native tool or the session made, run `git switch -c <branch>`, or `git switch <branch>` when it already exists.

   This step is done when `git branch --show-current` prints `<branch>` in a worktree under the main checkout. The main checkout stays on its branch: the record, the plan and the pull request start from the worktree.
4. Copy the spec into this repo's `docs/superpowers/specs/<slug>-<n>.md` as a record and commit only that file: `git add <path>`, then `git commit -m "docs: spec of <slug>/<n>" -- <path>`. When `<path>` already holds this text, as when a milestone is started again, skip the commit. Cadre's copy stays the original: cadre reads only its own.
5. Plan this repo's part with the `cadre:writing-plans` skill: load it, and hand it the spec copy's path, this repo's part and, for one app's pull request, its app.

## Track a milestone's implementation

A spec or plan tracked in Cadre says so on the line under its title. When you implement one, for example while executing such a plan:

- Load `cadre:pr-description` before writing or editing its pull request's description. When the pull request is already open without its `Cadre:` line, add it: write `gh pr view <pr-url> --json body -q .body` to a temporary file, add the line, then run `gh pr edit <pr-url> --body-file <file>`.
- A feature spec names only its project, `<slug>`: its increment `<i>` is milestone `<slug>/<i>`. Start it as "Start a milestone" says, so its plan says it is tracked too.

## Link a pull request by hand

A pull request opened without the `Cadre:` line, or before the cadre GitHub App was installed, is linked by hand with `cadre pr link <pr-url> <slug>/<n> --json`, with `--app <app>` for one app, or `--none` in place of `<slug>/<n>` to unlink it. Report the `project_url` field of the JSON body. A `Cadre:` line in the description overrides this link, so edit that line.

## The first step with no pull request

Run `cadre status <slug> --json`. Its `milestones` entry whose `number` is `<n>` lists its `steps` in deploy order, each with its `repo`, its `app` (null for a whole-repo step) and the open and merged `pull_requests` that count on it. The first step whose `pull_requests` is empty is the first step with no pull request. Ask the person which step is next when every step already has a pull request, or when they say one isn't linked yet: `cadre status` counts only linked pull requests, and one opened before the cadre GitHub App was installed is linked as "Link a pull request by hand" says.

## When `cadre` refuses

- `No project <slug> on <server>.` or `No milestone <slug>/<n> on <server>.`: check the slug and number with the person.
- `GitHub has no pull request at <url>.`: check the URL with the person.
- `GitHub isn't connected on <server> yet. …`: tell the person, and stop.
- `app: must be lowercase letters, digits, - or _`: check the app's name with the person.
- `url: is in a repo no project names`: the repo needs to be in a project first, as "Change a project" in [project.md](project.md) adds it.
