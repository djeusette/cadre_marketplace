# Cadre marketplace move — design

> Not tracked in Cadre, as David chose (2026-11-26). Each increment is one PR, planned with `superpowers:writing-plans` once the previous one has shipped. Its status line becomes `- [x] PR #<n>` when that PR opens.

Brainstormed with David on 2026-11-26, then reviewed twice by Fable and once by a builder check. Their points are folded in. The calls I made are marked *(my call)*.

**Words.** *cadre* is the plugin; *the cadre marketplace* is `djeusette/cadre_marketplace` (marketplace name `cadre`); *Cadre* is the app. *colette-club* is `colette-club/colette-marketplace`.

## Intent

David's way of working lives in two places today: brainstorm a feature into increments, plan one at a time, describe each PR to one standard, review it, and prove its branches.

- The `cadre` plugin sits in the cadre marketplace, which is public. It brainstorms features into Cadre milestones.
- Everything else sits in colette-club:
  - the `colette` plugin (`brainstorming`, `writing-plans`);
  - `engineering-review` (the principles, the review companion, `pr-description`, `break-check`), with Cloudflare's `security-audit` pinned beside it.

David wants to use Cadre more and more, and colette-club to be only about conventions. So the way of working moves to the cadre marketplace, and the team installs it from there. colette-club keeps `elixir-phoenix-conventions` and `flutter-conventions-guide` only. `cadre` stays independent: anyone can install it and use it with Cadre without the rest.

## Goals

- `cadre` holds the way to design, plan and describe a change: its CLI skill, `cadre:brainstorming`, `cadre:writing-plans` and `cadre:pr-description`.
- `engineering-review` lives in the cadre marketplace and keeps `engineering-principles`, `review-companion`, `review-passes`, `review-report` and `break-check`. It depends on `cadre` (for `cadre:pr-description`) and on `security-audit`, which the cadre marketplace lists, pinned.
- Every team repo installs `engineering-review` and `security-audit` from the cadre marketplace.
- colette-club holds only the two conventions plugins. `colette` is gone, and nothing the team uses names it or names colette-club's former plugins.

## Non-goals

- Changing what any moved skill does, beyond what the move needs: the merged brainstorm, the planning modes below, and skill names that change with the plugin.
- Moving `elixir-phoenix-conventions` or `flutter-conventions-guide`.
- Keeping the git history of the moved files in the cadre marketplace. It stays in colette-club, and each copy commit names the source sha.
- The shared break-check runner. It is decided here (see "Effect on the break-check spec") and built after the move.

## Anti-goals

- A release where a skill, a spec or a repo's settings name a skill or plugin that is gone, such as `colette:writing-plans` naming `engineering-review:pr-description` after it has moved, or a repo enabling `engineering-review@colette-club` after colette-club drops it.
- Two plugins with the same name enabled on one machine, such as `engineering-review@colette-club` beside `engineering-review@cadre`. The docs don't say which one's skills win.
- `cadre` depending on anything of David's or colette's. Its only dependency is `superpowers@claude-plugins-official`.
- Unreleased work reaching the team. Users update when an entry's version changes, but a fresh install takes `main` as it is. So every merge to the cadre marketplace's `main` is a release with its version bumped, as its PRs already are ("Cadre 0.32.0: …").
- A teammate moved onto Cadre by an install. `cadre:brainstorming` and `cadre:writing-plans` run only when someone asks for them, by name or through the `cadre` skill, as colette's did. Otherwise Claude brainstorms and plans with plain superpowers. David chose this.

## Constraints

From the Claude Code docs (marketplace reference, manifest reference, dependencies, hosting):

- **Dependencies by bare name** resolve in the marketplace the plugin was installed from ("Bare names resolve against this plugin's own marketplace"). So the cadre marketplace lists `cadre`, `engineering-review` and `security-audit`.
- **Versions.** Users get a new copy only when a plugin's version changes. `plugin.json`'s version takes precedence over the entry's, and the cadre marketplace keeps the version in both, as its release step and test do today.
- **A removed plugin** stays installed and reports that it is not found in the marketplace. A `renames` entry mapping its name to `null` tells users it was removed instead.
- **Installing a dependency that an update adds** needs Claude Code 2.1.319 or later. On an older client, `engineering-review` stays disabled until `claude plugin update engineering-review@cadre` and `/reload-plugins` are run.
- **`superpowers` has no version** in cadre's dependency, as today. A range would resolve against tags named `superpowers--v<version>`, which this design does not rely on. cadre's README gains the note that its skills need superpowers 7.0 or later (colette's README has it today).
- **No EP IDs in cadre.** Its skills cannot cite `engineering-principles`. They state the rules they apply in their own words, as `cadre:brainstorming` does for milestones. They may name another skill (`break-check`, `engineering-principles`) for a repo whose Skills table lists it.
- **No "colette" in cadre's skill files or README.** `test_no_skill_file_names_colette` and `test_readme_installs_cadre_with_superpowers` forbid it, and both stay.
- **Evals cannot run on David's Mac.** Every behaviour a skill must have is pinned by its wording tests and checked by dry runs by subagent. There is one dry run per mode, and one per skill where a plain "brainstorm this" or "plan this" request, with `cadre` installed, stays on superpowers. Each eval case that moves is recorded as not measured.
- **During the move, edits go to the cadre marketplace's copies only.** Each colette-club skill is frozen from the increment that forks it until colette-club deletes it *(my call)*:
  - `pr-description` from increment 1;
  - `colette:brainstorming` from 2;
  - `colette:writing-plans` from 3;
  - the rest of `engineering-review` from 4.
- **A project-enabled plugin loads only once it is installed on each machine.** Settings merge per plugin id, so a repo's switch reaches a person only after they install the new plugin, and a user-scope `@colette-club` copy beside a project-scope `@cadre` one loads both.

## Consumers

| Who | What names colette-club's plugins today | Changes at |
| --- | --- | --- |
| colette-api, colette-app, rooms-app, admin-app | `.claude/settings.json` enables `engineering-review@colette-club` and `security-audit@colette-club`; the Skills table installs `engineering-review` and `security-audit` `@colette-club` | 6 |
| kinfield | `.claude/settings.json` enables `engineering-review@colette-club` | 6 |
| cadre | `.claude/settings.json` enables `engineering-review@colette-club` and `colette@colette-club`; the spec `docs/superpowers/specs/2026-10-22-cadre-design.md` has the `colette:writing-plans` plan line | 6 |
| colette-app `docs/superpowers/specs/2026-10-22-english-pages-design.md`, colette-api `docs/superpowers/specs/2026-11-09-live-recording-statuses-design.md` and `2026-11-18-referral-code-tracking-design.md` | The `colette:writing-plans` plan line | 6 |
| colette-marketplace itself | `.claude/settings.json` enables `engineering-review` and `security-audit` `@colette-club`; its `AGENTS.md` Skills table installs them from there | 6 |
| cadre_marketplace | Will need `engineering-review` and `security-audit` rows for its own work once it holds them | 6 (`@cadre`) |
| admin-app `docs/superpowers/specs/colette-live-24.md`, and recent plans such as rooms-app `shared-interests-4` and colette-app `live-feels-like-home-20` and `-21` | Name `engineering-review:pr-description` | 6: rewritten to `cadre:pr-description` in each spec or plan that is not fully shipped |
| David's `~/.claude/settings.json` | Enables `colette`, `engineering-review` and `security-audit` `@colette-club`, and `cadre@cadre` | Before 6: the three `@colette-club` ones dropped |
| Each teammate's machine | User-scope copies, unknown; the installed plugins | Before 6: user-scope copies dropped. After each repo's PR: the `@cadre` plugins installed |

From increment 6, each repo that enables `engineering-review@cadre` also installs `cadre` and `superpowers` through its dependencies, rooms-app, admin-app and kinfield included. superpowers' SessionStart hook then runs in every session there. It follows from `engineering-review` depending on `cadre`, and David accepted it. The team is told when the repos switch. Unshipped specs and plans that name `engineering-review:pr-description` are listed in the table.

## Approaches

1. **Copy, switch, remove (chosen).** The cadre marketplace gains each skill first. The team repos then switch to it, and colette-club deletes its copies last. Every PR deploys on its own, and for a short time a skill exists in both marketplaces.
2. **Move with history.** `git subtree` or `filter-repo` into the cadre marketplace. Blame survives, but a public repo gets two unrelated histories merged in, which is a risky import for little gain over a sha link.
3. **One PR per repo.** Fewer PRs, but it breaks the smallest-increment rule, and `colette:writing-plans` would name a skill that is already gone.

David chose 1. He first chose for colette-club to list the moved plugins by `git-subdir`, with a version and a release tag. Then he chose for colette-club to hold only conventions, which drops those entries, their tags and the manifest test they needed.

## The design

### `cadre:brainstorming`, always tracked in Cadre

David chose this over a skill with two endings (tracked, or untracked with status lines).

- It replaces `plugins/cadre/skills/cadre/brainstorm.md`, which goes. It keeps that file's flow: `superpowers:brainstorming` as written, with cadre's rules on top. A feature always gets a written spec; its repos, apps and deploy order are covered; the code is read without asking; and the milestones are vertical slices.
- Before it brainstorms, it runs cadre's CLI and sign-in checks ("Before you start", "Install or update the CLI" and "Sign in" in the `cadre` skill), so a brainstorm never ends unable to register.
- The spec carries the "Tracked in Cadre" line. It has no plan line and no status lines, because Cadre shows where each milestone stands.
- It ends by registering the project: `project.md`'s "Create a project" hands over to it at step 1 and takes the spec back at step 2.
- It runs when it is named, or when the `cadre` skill creates a project. Its description says so.

### `cadre:writing-plans`

It runs when it is named, or when the `cadre` skill starts a milestone. Its modes, each with a dry run by subagent before its PR:

- **A Cadre milestone.** It plans one repo's part of one milestone. It takes over `milestone.md` step 5:
  - it reads the Skills table;
  - it runs `superpowers:writing-plans` with the rules on top: this repo's part only, the skills each task needs, the `Cadre:` line and `## Before deploying`, and the "Tracked in Cadre" header.
  - `milestone.md` steps 1 to 4 stay and hand over to it.
- **A spec that is not tracked in Cadre** goes to "Create a project" in the `cadre` skill, which registers it. That skill brainstorms the missing End goal and Increments through `cadre:brainstorming` when they are missing. Then the first milestone is planned. A spec tracked in Cadre that also has colette's status lines is planned as a Cadre milestone.
- There is no status-lines mode. David chose this over keeping one: the two live specs that still use colette's status lines are registered in Cadre in increment 6. They are cadre's `2026-10-22-cadre-design.md` and colette-app's `2026-10-22-english-pages-design.md`.
- **Requirements with no spec.** As colette does: one increment planned directly, or a spec first through `cadre:brainstorming`.
- Every plan's PR step names `cadre:pr-description`. `milestone.md` step 5 already names it from increment 1, where the call-list test gains it.
- It never cites an EP ID. It states the increment rules it applies: one feature per PR, the smallest deployable step, code files counted without tests and docs, and consumers named.

### `cadre:pr-description`

- A copy of `engineering-review:pr-description`, with every EP ID replaced by the rule in words. The Cadre line and Before deploying rules that `milestone.md` held move into it.
- **Break checks:** it keeps the part and names the `break-check` skill for repos whose Skills table lists it. It states the rule for which rows belong to the change itself *(my call: a PR's description must not depend on a skill the repo may not have)*.
- It becomes the one source for the `Cadre:` line and the `## Before deploying` rules. `milestone.md`'s "The pull request's description" points to it instead of restating them (increment 1).

### `engineering-review` in the cadre marketplace

Two steps, so that the copy is only a copy:

- **The copy (increment 4).** The whole plugin, verbatim: skills (`pr-description` included), agents, hook, scripts and evals. It depends on `security-audit` only.
  - The cadre marketplace's `marketplace.json` gains `engineering-review` (relative source) and `security-audit` (Cloudflare's repo, pinned to the same full sha as colette-club's).
  - `check_plugin.py` runs from its new home. `_check_pinned_sources` stays as it is: `security-audit` is pinned, and the rule keeps every third-party source pinned.
  - `test_marketplace_lists_cadre_last_at_the_plugin_version` stops requiring `cadre` to be last (EP-I3: the marketplace now holds three plugins).
  - The cadre marketplace gains a CI workflow that runs cadre's Ruby tests and `engineering-review`'s Python tests *(my call: the repo has no CI, and now has two suites)*. It also fails a PR that changes `plugins/<name>/` without bumping that plugin's version, since a fresh install takes `main` and every merge must be a release.
  - `plugin.json`'s `homepage` and `repository` point at the cadre marketplace.
  - Its "Checks" and "Release" cover the new plugin. Its own Skills rows and settings for this work (`engineering-review:engineering-principles`, `security-audit:security-audit`, `mattpocock-skills:tdd`) come in increment 6, as `@cadre`.
  - Its README gains whatever the copied tests read from the root `README.md`: the `security-audit` and "Skills table" text.
  - The break-check spec is not copied: it names `colette:writing-plans` four times. See "Effect on the break-check spec".
- **The switch (increment 5).** `pr-description` leaves `engineering-review`, and the plugin depends on `cadre` for `cadre:pr-description`.
  - What changes: `agents/review-companion.md`'s `skills:` list, `review-companion`, `review-passes`, `review-report`, `break-check/contract.md`, EP-F5, `test_check_plugin.py`'s 31 references and the eight `pr-description-*` evals.
  - The builder checks first that an agent's `skills:` accepts another plugin's skill. If it does not, the agent loads `cadre:pr-description` with the Skill tool instead.

### Switching the team repos

Increment 6 is one Cadre milestone with one PR per repo, in the Consumers table's order, cadre_marketplace included. Each PR:

- adds the cadre marketplace under `extraKnownMarketplaces` (`{"source": "github", "repo": "djeusette/cadre_marketplace"}`, with `autoUpdate: true` as colette-club has);
- enables `engineering-review@cadre` (and `security-audit@cadre` where the repo enables it) in place of the `@colette-club` ones;
- changes its Skills table's install lines to `@cadre`;
- handles each spec that has the `colette:writing-plans` plan line:
  - cadre-design and english-pages are registered in Cadre with the `cadre` skill, and their plan line becomes the "Tracked in Cadre" line;
  - live-recording-statuses, already tracked, drops the plan line;
  - referral-code-tracking, fully shipped, drops it too;
- rewrites `engineering-review:pr-description` to `cadre:pr-description` in specs and plans that are not fully shipped;
- in cadre, drops `colette@colette-club`.

A repo that enables `elixir-phoenix-conventions@colette-club` (colette-api, kinfield, cadre) keeps colette-club under `extraKnownMarketplaces` for it.

Repos switch first and machines follow, so that no machine ever loads a plugin from both marketplaces:

1. **Before the first PR:**
   - David drops the three `@colette-club` plugins from his `~/.claude/settings.json`, and the team drops any it enabled at user scope. Each repo's project settings still enable its own.
   - The team is told the commands and that `engineering-review` now brings `cadre` and `superpowers`.
2. **After each repo's PR merges:** each person runs the written commands once, to install the `@cadre` plugins and uninstall the `@colette-club` ones that no repo still enables. The builder checks the exact commands against the docs.
3. **Increments 7 and 8 wait** until every person has run them, because a `renames` entry mapping to `null` drops the old key from their settings.

## Effect on the break-check spec

David chose one shared runner (2026-11-26):

- It ships once in `engineering-review`, ported from cadre's Ruby runner and made generic.
- Each repo keeps its profile in `.break-check.json`:
  - the test command, with a `{files}` placeholder, its env and its partition;
  - the failing-test, compile-error, infrastructure and refusal patterns;
  - the timeout;
  - the watched paths;
  - the noise and doc-block patterns.
- The runner needs Ruby 3.2 or later, which `break-check`'s "Before you start" checks.

`docs/superpowers/specs/2026-11-25-break-check-design.md` stays in colette-club. After increment 5 and before increment 8 deletes it, its unshipped work is brainstormed again with `cadre:brainstorming`, from that spec, into its own Cadre project. The new spec lives in the cadre marketplace. Roughly in this order:

- the shared runner, with `.break-check.json`, its tests, and `contract.md` as its documentation;
- cadre adopting it, replacing `script/break_check.rb`;
- the five Known gaps fixed in it: `--table BASE`, freeing a stale proof's name, recording each proof's profile, fencing table cells that hold backticks, and listing branches narrowed only by deletion;
- the plans, in `cadre:writing-plans`:
  - a repo with no `.break-check.json` writes one in its plan's first task;
  - per-task breaks run in the implementer's own session;
  - the before-the-PR step goes into every plan's final review;
  - "Before you start" checks for `break-check`;
  - then cadre's `AGENTS.md` row and memory notes.

## Left to the builder

- The wording of the three cadre skills, within the rules above.
- Which colette eval cases become cadre eval cases, and which are dropped with `colette`. Every case that moves is recorded as not measured.
- Version numbers, following each marketplace's release steps.

## End goal

The cadre marketplace holds `cadre` (CLI, brainstorming, planning, PR descriptions), `engineering-review` (principles, review, break check) and a pinned `security-audit`, and every team repo installs them from there. colette-club holds only the team's conventions. No skill, spec or setting names a skill or plugin that no longer exists.

## Increments

### Increment 1 — `cadre:pr-description` (cadre marketplace)

- **Delivers:** a cadre user can write and check a PR's title and description to the standard without `engineering-review`.
- **Deployable alone:** a new skill. `engineering-review:pr-description` stays as it is.
- **Consumers:** none.
- **Code files:** 2 — `.claude-plugin/marketplace.json`, `plugins/cadre/.claude-plugin/plugin.json` (the version; the skill, its tests and README are docs and tests)
- [x] PR #34

### Increment 2 — `cadre:brainstorming` (cadre marketplace)

- **Delivers:** creating a project brainstorms through one skill that checks the CLI and sign-in first and ends with the project registered.
- **Deployable alone:** `project.md` step 1 hands over to it, and `brainstorm.md` goes. Projects already registered are unaffected. `test_skill_files_call_only_superpowers_skills_and_cadre_itself` gains `cadre:brainstorming` (EP-I3: cadre now calls its own skill).
- **Consumers:** none.
- **Code files:** 2 — `.claude-plugin/marketplace.json`, `plugins/cadre/.claude-plugin/plugin.json`
- [x] PR #35

### Increment 3 — `cadre:writing-plans` (cadre marketplace)

- **Delivers:** a milestone is planned by one skill, and so are requirements with no spec. A spec not tracked in Cadre is registered first.
- **Deployable alone:** `milestone.md` step 5 hands over to it, and the call-list test gains `cadre:writing-plans`. `colette:writing-plans` keeps working for anyone who still has `colette`. colette's planning behaviours that apply to milestones and requirements move here, as wording tests and dry runs.
- **Consumers:** none.
- **Code files:** 2 — `.claude-plugin/marketplace.json`, `plugins/cadre/.claude-plugin/plugin.json`
- [ ] Not shipped

### Increment 4 — `engineering-review` copied into the cadre marketplace (cadre marketplace)

- **Delivers:** `engineering-review@cadre` installs the principles, the review companion, `pr-description` and the break check, with `security-audit`. CI runs both suites.
- **Deployable alone:** a verbatim copy. No team repo enables it yet.
- **Consumers:** none.
- **Code files:** 9 — `.claude-plugin/marketplace.json`, `.github/workflows/<checks>.yml`, `plugins/engineering-review/.claude-plugin/plugin.json`, `plugins/engineering-review/hooks/hooks.json`, `plugins/engineering-review/scripts/check_plugin.py`, `plugins/engineering-review/scripts/guard_reader_bash.py`, and the three `plugins/engineering-review/agents/*.md` files. It cannot be smaller: the plugin installs as one unit.
- [ ] Not shipped

### Increment 5 — `engineering-review` uses `cadre:pr-description` (cadre marketplace)

- **Delivers:** the review companion and EP-F5 point at `cadre:pr-description`, and installing `engineering-review@cadre` installs `cadre`.
- **Deployable alone:** `cadre:pr-description` has existed since increment 1. No team repo enables `engineering-review@cadre` yet.
- **Consumers:** none.
- **Code files:** 4 — `.claude-plugin/marketplace.json`, `plugins/engineering-review/.claude-plugin/plugin.json`, `plugins/engineering-review/agents/review-companion.md`, `plugins/engineering-review/scripts/check_plugin.py` (if a check names `pr-description`)
- [ ] Not shipped

### Increment 6 — the team repos install from the cadre marketplace (colette-api, colette-app, rooms-app, admin-app, kinfield, cadre, colette-marketplace, cadre_marketplace)

- **Delivers:** each team repo gets `engineering-review` and `security-audit` from the cadre marketplace, with `cadre` and its planning skills, and no spec names `colette:writing-plans`.
- **Deployable alone:** colette-club still serves its copies, so a repo not yet switched keeps working. Each repo's PR switches all of its settings at once, so no repo enables a plugin from both marketplaces.
- **Before deploying:** David's and the team's user-scope `@colette-club` copies dropped, and the team told, as "Switching the team repos" says.
- **Consumers:** the Consumers table.
- **Code files:** 1 per repo — `.claude/settings.json` (the Skills tables and specs are docs)
- [ ] Not shipped

### Increment 7 — the `colette` plugin goes (colette-marketplace)

- **Delivers:** one way to brainstorm and plan for the team, through `cadre`.
- **Deployable alone:** `colette`'s entry and `plugins/colette/` are removed, a `renames` entry maps `colette` to `null`, and README and AGENTS.md drop it.
- **Before deploying:** every PR of increment 6 merged, and every person has run the switch commands.
- **Consumers:** none left after increment 6.
- **Code files:** 2 — `.claude-plugin/marketplace.json`, `plugins/colette/.claude-plugin/plugin.json` (deleted)
- [ ] Not shipped

### Increment 8 — colette-club holds only conventions (colette-marketplace)

- **Delivers:** colette-club lists `elixir-phoenix-conventions` and `flutter-conventions-guide` only.
- **Deployable alone:** the `engineering-review` and `security-audit` entries and `plugins/engineering-review/` are removed, with the break-check spec. `renames` entries map both names to `null`. README describes the two conventions plugins and points to the cadre marketplace for the rest *(my call)*.
- **Before deploying:**
  - every PR of increment 6 merged, and every person has run the switch commands;
  - increment 7 merged, since `colette` depends on `engineering-review`;
  - the break-check spec's new Cadre project registered.
- **Consumers:** none left after increment 6.
- **Code files:** 9 — `.claude-plugin/marketplace.json`, and the eight code files of `plugins/engineering-review/` (deleted)
- [ ] Not shipped
