# cadre:pr-description — plan

Spec: `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, Increment 1 only. PR title: `Cadre marketplace move (1/8): cadre:pr-description`.

**Goal:** cadre gains `cadre:pr-description`, the PR title and description standard, with no EP IDs, and it becomes the one source for the `Cadre:` line and `## Before deploying` rules. cadre 0.32.0 → 0.33.0.

**Skills to load:** `superpowers:writing-skills`, `mattpocock-skills:writing-for-agents` (wins where they disagree), `engineering-review:engineering-principles` (for the reviews), `mattpocock-skills:tdd`.

**Source:** `plugins/engineering-review/skills/pr-description/SKILL.md` at colette-marketplace `d8fbb871` (unchanged since 0.21.0, `90a5afd5`). The commit that copies it names that sha.

**Checks:** `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`. Each test is changed first and seen red, then the text.

## Task 1: tests first (red)

In `plugins/cadre/test/plugin_test.rb`:

1. A new `PrDescriptionTest` class, reading `plugins/cadre/skills/pr-description/SKILL.md`:
   - frontmatter holds only `name: pr-description` and a `description` that starts with `The standard for a pull request's title and description` and has a `Use when` trigger for writing, checking or rewriting one;
   - the sections, in order: `## The title`, `## The parts`, `## Template`, `## Not essential`, `## Marked spots`, `## Pictures`, `## Rewriting a description`, `## A repository's own template`;
   - the seven parts, numbered in order: What it does, Before deploying, How it works, Behind the scenes, Screenshots and videos, Break checks, The Cadre line;
   - the title forms `<feature> (<i>/<n>): <what it delivers>` and `<feature>: <what it delivers>`, and the sequence rules;
   - the rules each EP ID stood for, in words:
     - consumers: every frontend and app that depends on the change, whether each must change, and the deploy order;
     - deploy: works while the previous version still runs, unfinished work out of users' reach, a rollback loses no data;
     - loosened checks: the reason for each check turned off or weakened;
   - **Before deploying:** the exact heading line `## Before deploying`, `- [ ]` items, "A change that needs nothing has no section.", that Cadre shows the PR as held until its items are ticked, and that its items are ticked as the `cadre:cadre` skill's "Tick a Before deploying item" says;
   - **The Cadre line,** moved from `milestone.md`:
     - `Cadre: <slug>/<n>`, and `Cadre: <slug>/<n> <app>` for a PR for one app;
     - the app is its name in Cadre as `cadre repo show` lists it (a target's `name`): lowercase letters, digits, `-` or `_`;
     - a line whose app isn't such a name links nothing;
     - a feature spec's increment `<i>` is milestone `<slug>/<i>`;
   - **Break checks:**
     - names the `break-check` skill for a repo whose Skills table lists it;
     - states the belonging rule itself: a row belongs to the change when its `from` spans a line the change adds or changes, or sits next to a line it deletes;
     - the marker `> **Break checks to add:** <runner> --table`;
   - the two picture markers, and the zsh `${sha}` note;
   - the rewrite rules: keeps every picture link, keeps each `## Before deploying` item and its tick, keeps the Break checks table byte for byte beyond dropped rows, keeps the Cadre line.
2. `milestone.md`'s "The pull request's description" section names `cadre:pr-description` for both rules and restates neither. The assertions that pin those rules in `milestone.md` today move to `PrDescriptionTest`.
3. `milestone.md` step 5's bullet says the plan's PR step follows `cadre:pr-description`, in place of "the two rules … given in full".
4. `test_skill_files_call_only_superpowers_skills_and_cadre_itself` gains `cadre:pr-description`.
5. `test_no_skill_file_pushes_or_commits_everything` allows exactly the assets-branch push in `pr-description/SKILL.md`, `git push origin "${sha}:refs/heads/assets/pr-<n>"`. Its comment states the reason (EP-I3): a description's pictures need a commit of their own on an assets branch, never on the PR's branch. Every other push stays refused.
6. Version: `0.33.0` in `test_marketplace_lists_cadre_last_at_the_plugin_version`.
7. README: the cadre bullet names PR descriptions and stays within 70 words.

Run: red, one failure per new rule.

## Task 2: the skill and its pointers (green)

1. Copy the source to `plugins/cadre/skills/pr-description/SKILL.md`. Then:
   - replace the opening's "rule EP-F5 of `engineering-principles`" sentence with what the standard is for, and drop `review-companion`;
   - write each EP-E5, EP-I5, EP-I3 out in words, and drop `(elixir #59)`;
   - the Before deploying part gains the tick line;
   - the Cadre line part holds `milestone.md`'s full rules, with no "Follow the `cadre:cadre` skill" (it is in cadre now);
   - the Break checks part states the belonging rule and names `break-check` as "the `break-check` skill, for a repo whose Skills table lists it".
2. `milestone.md`: the PR description section points to `cadre:pr-description`, and step 5's bullet changes as Task 1 says.
3. `plugin.json` and `marketplace.json`: `0.33.0`. README bullet updated.
4. Run the checks: green. Commit: `Cadre 0.33.0: cadre:pr-description, the PR standard` naming the source sha.

## Task 3: dry runs

Two fresh subagents get only the new `SKILL.md` and a scenario, and draft a description:

- a PR for one app of a Cadre milestone that needs a secret set first;
- a change whose runner table holds a row of another change.

The drafts pass when they hold:

- the `Cadre: <slug>/<n> <app>` line and a `## Before deploying` item;
- in the second, the foreign row dropped and the count lowered.

## Finishing

1. Run a fresh rule-by-rule `engineering-principles` review and a `writing-for-agents` review of the diff, fix every finding (Minors included), and rerun until clean.
2. Push the branch and open the PR with `cadre:pr-description`'s standard. David merges.
3. Once the PR exists, set Increment 1's status line to `- [x] PR #<n>` in the spec, on the same branch, and push.

## Fable's review, folded in

Built on branch `cadre-marketplace-move-1`, stacked on the spec's commit; the PR holds the spec, this plan and the increment.

- **Order (vertical slices).** Copy the source verbatim first and watch the existing EP and push guards go red. Then fix one rule at a time, each with its test changed first: the EP IDs (the frontmatter's `(EP-F5)`, the title example `PR description standard (1/4): EP-F5 and the companion's check`, which becomes `Wish reminders (2/3): members choose when they are reminded`, and the body's EP-E5, EP-I5, EP-I3 and `elixir #59`); the push guard (loosened with its reason, so it cannot be seen red); then each part's rules.
- **Step 5 keeps the rules reaching the executor.** The plan's PR task names `cadre:pr-description` among the skills it loads, which holds the `Cadre:` line and `## Before deploying` rules. A third dry run plans a milestone that needs a secret with the new `milestone.md`, and passes when the plan's PR task names the skill. `track_section` points straight to `cadre:pr-description`.
- **Break checks in table terms.** A row belongs to the change when the code left of its Swap arrow spans a line the change adds or changes, or sits next to a line it deletes. The template's "as `break-check` shows it" and part 6's "(`break-check`)" become "as the runner prints it" and "the `break-check` skill, for a repo whose Skills table lists it". Dry run 2 gets a diff and a runner-shaped table (`<details><summary>Break checks (N)`).
- **Tests that move or change:** `test_the_cadre_line_links_a_pull_request_and_names_its_app` and `test_the_pull_request_lists_what_a_deploy_needs_first` move to the new skill. The `everything.scan` count becomes the new skill's, the tick link becomes "the `cadre:cadre` skill's", and "given in full" is replaced. `test_it_links_a_pull_request_to_an_app` counts `as `cadre repo show` lists it` once in the new skill and zero times in `milestone.md`.
- **Pins ported from the source suite:**
  - "never invented";
  - "drops every instruction aimed at a reviewer or an AI";
  - "A draft is done when";
  - the exact-heading exception;
  - the four Pictures steps;
  - "When no row is left".
- **README:** the cadre bullet trades "brainstorms a feature into milestones, each with its spec and designs, and registers them" for a shorter wording that adds PR descriptions, staying at or under 70 words.
- **Dry runs:**
  - four: one-app Cadre PR with a secret; a foreign break-check row; a rewrite of an existing description with a ticked item and a picture; and the step 5 plan;
  - each brief forbids loading `engineering-review:pr-description` and `break-check`;
  - the consumers line must name each app and whether it changes;
  - a failed run means test first, then text.
