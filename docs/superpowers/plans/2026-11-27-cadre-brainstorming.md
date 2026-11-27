# cadre:brainstorming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** cadre gains `cadre:brainstorming`, one skill that checks the CLI and sign-in first, brainstorms a feature into a spec tracked in Cadre, and hands it to "Create a project" to register. `brainstorm.md` goes. cadre 0.33.0 → 0.34.0.

**Architecture:** `plugins/cadre/skills/cadre/brainstorm.md` moves (`git mv`) to `plugins/cadre/skills/brainstorming/SKILL.md` and gains frontmatter, so the flow and its history stay. Its links into the cadre skill become `../cadre/…`. `project.md` step 1 invokes the skill, and step 6 points to its handoff.

**Tech Stack:** Markdown skills, Minitest (`plugins/cadre/test/plugin_test.rb`).

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, "`cadre:brainstorming`, always tracked in Cadre" and Increment 2 only. PR title: `Cadre marketplace move (2/8): cadre:brainstorming`.

**Skills to load:** `superpowers:writing-skills`, `mattpocock-skills:writing-for-agents` (wins where they disagree), `engineering-review:engineering-principles` (for the reviews), `mattpocock-skills:tdd`.

**Checks:** `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`. Each test is changed first and seen red, then the text.

## Global Constraints

- cadre depends on `superpowers@claude-plugins-official` alone, with no version.
- No EP ID and no "colette" in any skill file or the README (`test_no_skill_file_names_colette`, `test_readme_installs_cadre_with_superpowers`, the EP guard in the call-list test).
- The skill runs only when it is named or when the `cadre` skill creates a project, never on a plain "brainstorm this": with cadre installed, that stays on `superpowers:brainstorming`.
- The spec carries the "Tracked in Cadre" line, and no plan line and no status lines.
- The README cadre bullet stays at or under 70 words.
- Every merge to `main` is a release: 0.34.0 in `plugin.json`, `marketplace.json` and `test_marketplace_lists_cadre_last_at_the_plugin_version`.
- Evals cannot run on this Mac: every behaviour is pinned by wording tests and dry runs; cases are recorded as not measured.

## Review Focus

- A person who names `cadre:brainstorming` while not signed in, or without the CLI, is stopped before the brainstorm, not at registration (Task 2 pins it; dry run 2 checks it).
- A person who says "brainstorm this", or "brainstorm a feature for Cadre", with cadre installed gets `superpowers:brainstorming`, not cadre's (Task 1 pins the description; dry run 3 checks it).
- A person on superpowers older than 7.0 (no builder check) is told to update it and stopped (Task 2 pins it).
- A brainstorm named directly still ends with the project registered, not with a spec and nothing else (Task 1 pins the handoff to step 2; dry run 1 checks it).
- A link from the new skill into the cadre skill's folder resolves (`test_every_link_between_skill_files_leads_to_a_file` already walks every skill file; Task 1 keeps it green).

---

### Task 1: the skill replaces `brainstorm.md`

**Files:**
- Move: `plugins/cadre/skills/cadre/brainstorm.md` → `plugins/cadre/skills/brainstorming/SKILL.md`
- Modify: `plugins/cadre/skills/cadre/project.md` ("Create a project" steps 1 and 6), `plugins/cadre/skills/cadre/SKILL.md` (the "belong to project.md" line)
- Test: `plugins/cadre/test/plugin_test.rb`

**Interfaces:**
- Produces: the skill `cadre:brainstorming` at `plugins/cadre/skills/brainstorming/SKILL.md`, with sections `## Before you start`, `## Run superpowers brainstorming`, `## What a milestone is`, `## Drafting the milestones`, `## The feature spec`, `## The handoff`.

- [ ] **Step 1: Change the tests**
  - `BrainstormTest` becomes `BrainstormingTest`: it includes `Sections`, and its reader `skill` reads `plugins/cadre/skills/brainstorming/SKILL.md` (today `brainstorm`). Every assertion it holds stays, with these changes:
    - `"step 3 of \"Create a project\" in [project.md](../cadre/project.md)"`;
    - `test_it_hands_back_to_the_cadre_skill_instead_of_writing_plans` asserts `%q{follow "Create a project" in [project.md](../cadre/project.md) from step 2}` in `## The handoff`, in place of `"Go back to step 2"`;
    - "Invoke it from this skill, not through a workflow that wraps it".
  - New `test_frontmatter_names_the_skill_and_when_it_runs`: keys `name` and `description` only; `name: brainstorming`; the description exactly `Cadre brainstorming, which ends with the feature registered as a Cadre project. Use only when the person names it ("cadre:brainstorming", "cadre's brainstorming"), or when the cadre skill calls it from "Create a project".` It opens on `Cadre`, not on the plain trigger it must not match.
  - `test_brainstorm_names_apps` moves into `BrainstormingTest`.
  - `test_creating_a_project_brainstorms_through_brainstorm_md` becomes `test_creating_a_project_brainstorms_through_cadre_brainstorming`: `create_section` includes `` `cadre:brainstorming` `` and not `brainstorm.md`.
  - `test_it_builds_from_a_spec_the_person_names`: the sentence becomes `When there is none, or the spec the person names lacks either section, brainstorm the feature with the person through the `cadre:brainstorming` skill, from that spec when there is one.`
  - `test_a_corrected_spec_is_committed_alone_or_left_to_the_person`: `%q{commit it as "The handoff" in [the brainstorming skill](../brainstorming/SKILL.md) commits it}`.
  - `test_canvas_md_belongs_to_project_md`: `` "`canvas.md` and `design_link.rb` belong to project.md" ``, and `skill` does not include `brainstorm.md`.
  - `test_skill_files_call_only_superpowers_skills_and_cadre_itself`: the list gains `cadre:brainstorming`, with the comment `# cadre:brainstorming is cadre's own skill, which "Create a project" calls (EP-I3).`
- [ ] **Step 2: Run the checks.** Expected: red on the missing file (every `BrainstormingTest` errors) and on each changed `project.md` and `SKILL.md` sentence.
- [ ] **Step 3: Move the file alone:** `git mv plugins/cadre/skills/cadre/brainstorm.md plugins/cadre/skills/brainstorming/SKILL.md`.
- [ ] **Step 4: Run the checks.** Expected: red on the frontmatter, `../cadre/project.md`, "from this skill", the handoff sentence and `test_every_link_between_skill_files_leads_to_a_file`, so each changed sentence is seen red.
- [ ] **Step 5: Change the text**
  - Add the frontmatter above, and title it `# Cadre brainstorming`.
  - The opening: the brainstorm ends as a feature spec, and the handoff registers it as a Cadre project.
  - `project.md` links become `../cadre/project.md`; "from this file" becomes "from this skill".
  - `## The handoff`: after the commit, `Then follow "Create a project" in [project.md](../cadre/project.md) from step 2, with that spec.`
  - `project.md` step 1 and step 6, and `SKILL.md`'s line, as the tests say.
- [ ] **Step 6: Run the checks.** Expected: green.
- [ ] **Step 7: Commit** `cadre:brainstorming replaces brainstorm.md` (`git add` the named paths; `git commit -- <paths>`).

### Task 2: the skill checks superpowers, the CLI and sign-in first

**Files:** `plugins/cadre/skills/brainstorming/SKILL.md` (`## Before you start`, `## Run superpowers brainstorming`), the test file.

- [ ] **Step 1: Write the failing test** `test_it_checks_the_cli_and_the_sign_in_before_it_brainstorms`, on `section(skill, "## Before you start")`:
  - includes `[the cadre skill](../cadre/SKILL.md)`, `%q{"Before you start"}`, `%q{"Install or update the CLI"}`, `%q{"Sign in"}` and `"then come back here"`;
  - the superpowers check comes first: `index("`superpowers:brainstorming`") < index("[the cadre skill]")`.
  - New `test_it_stops_on_a_superpowers_older_than_7`: `## Run superpowers brainstorming` includes `"no builder check"`, `"older than 7.0"`, `"update the `superpowers` plugin"` and `"and stop"`.
- [ ] **Step 2: Run.** Expected: red on the missing link.
- [ ] **Step 3: Write** `## Before you start` as two numbered steps: the superpowers check as today; then run only those three sections of [the cadre skill](../cadre/SKILL.md), then come back here: they stop the run when `gh`, the CLI or the sign-in fails, so the brainstorm never ends unable to register. They run on every path, the one from "Create a project" included: three read-only commands. In `## Run superpowers brainstorming`: when the skill invoked has no builder check, it is older than 7.0: tell the person to update the `superpowers` plugin, and stop.
- [ ] **Step 4: Run.** Expected: green.
- [ ] **Step 5: Commit** `cadre:brainstorming checks superpowers, the CLI and sign-in first`.

### Task 3: release 0.34.0

**Files:** `plugins/cadre/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, the test file.

- [ ] **Step 1: Change the tests**
  - `test_marketplace_lists_cadre_last_at_the_plugin_version`: `"0.34.0"`.
  - `test_readme_sums_cadre_up_and_links_its_skill`: the bullet includes `[`cadre:brainstorming`](plugins/cadre/skills/brainstorming/SKILL.md) brainstorms a feature into a Cadre project`; the 70-word cap stays.
  - `test_readme_installs_cadre_with_superpowers`: the README includes `cadre's skills need superpowers 7.0 or later`, outside the bullet.
- [ ] **Step 2: Run.** Expected: red on the version and the bullet.
- [ ] **Step 3:** both manifests at `0.34.0`; the bullet drops "brainstorms a feature into milestones and registers them" from its list and gains the sentence `[`cadre:brainstorming`](…) brainstorms a feature into a Cadre project; [`cadre:pr-description`](…) sets the standard for PR descriptions.` The superpowers note goes under "Use it", after "Skip the first line …".
- [ ] **Step 4: Run.** Expected: green, the bullet at or under 70 words.
- [ ] **Step 5: Commit** `Cadre 0.34.0: cadre:brainstorming, the brainstorm tracked in Cadre`.

## Dry runs

Fresh subagents read only the new `SKILL.md` (and, where it links, the cadre skill's files) and never run a real `cadre` command or commit. Each brief names the skills above and forbids loading `colette:brainstorming`.

1. **A feature brainstorm, named, that ends registered.** The person names `cadre:brainstorming` for a two-repo feature and skips the questions. Passes when the run: runs `gh auth status`, `cadre version` and `cadre whoami --json` in that order before `superpowers:brainstorming`; opens no file past the cadre `SKILL.md` before the brainstorm; writes the spec with the tracking line, End goal and Increments and no status lines; asks for approval once; commits only that file; never invokes `superpowers:writing-plans`; goes to "Create a project" step 2 and stops at step 6's playback, before `cadre project create`.
2. **The CLI or the sign-in missing.** 2a: `cadre version` is still missing after the install; passes when it stops on the `PATH` message. 2b: `cadre whoami` prints `Not signed in. …`; passes when it asks for the Cadre URL. Neither asks a brainstorm question.
3. **Not asked.** Each subagent gets the skills list (superpowers' and cadre's descriptions as installed, the new one included) and one request. "brainstorm this: members can archive a wish", three fresh runs, and "brainstorm a feature for Cadre: wish reminders" pass when they pick `superpowers:brainstorming`; "use cadre's brainstorming for wish reminders" passes when it picks `cadre:brainstorming`.
4. **Create a project with no spec.** "create a Cadre project: members can archive a wish", through the `cadre` skill. Passes when step 1 invokes `cadre:brainstorming` once, the run returns to step 2 after the spec commit, and it reaches step 6's playback with nothing registered.

A failed run means test first, then text. Eval cases, none run and each recorded as not measured in the PR: the spec's shape; a large feature cut into three or more increments (no dry run); a plain request staying on superpowers; the handoff.

## Finishing

1. A fresh rule-by-rule `engineering-principles` review and a `writing-for-agents` review of `git diff origin/main...HEAD`; fix every finding, Minors included, and rerun until both are clean.
2. Push and open the PR to `plugins/cadre/skills/pr-description/SKILL.md`. David merges.
3. Set Increment 2's status line to `- [x] PR #<n>` in the spec on the same branch, and push.

## Fable's review, folded in

- Dry run 4 covers the mode where the `cadre` skill creates a project; dry runs 1 to 3 get sharper pass criteria, and dry run 3 five runs.
- Task 1 moves the file alone first, so each changed sentence is seen red, not masked by a missing file.
- The description opens on `Cadre` and names its two triggers in checkable terms.
- The checks are linked, not invoked: `cadre:cadre` would route to "Create a project" step 1 and back here. "then come back here" bounds them.
- The checks run on every path: a skip would key on who sent the run, which nothing observes, and save only three read-only commands.
- The README bullet lands at 70 words with ";", and the README gains the superpowers 7.0 note the spec's Constraints ask for, which no increment owned.
- From the frozen skill, only its version probe carries over, as the builder check superpowers 7.0 added.

## Reviews, folded in

The `engineering-principles` and `writing-for-agents` reviews of the branch changed it past the tasks above:

- `project.md` names its own folder for `design_link.rb` and the `cadre:cadre` skill on step 3, so it reads right when the brainstorm hands over to it; step 1 loads the skill, and step 6 points to the `git` commands in "The handoff".
- The version check comes before "follow it as written", and the skill takes the spec the person or "Create a project" names.
- The step's done-criterion points to "Sign in" instead of restating it; the heading order and "Run only" are pinned, and the cadre skill's rules for flags and unnamed refusals hold for the whole run.
- "Invoke it directly from this skill" replaces the negation about a wrapping workflow; the spec's Constraints no longer name `brainstorm.md`.
- The stop sentence names "those sections" and sits right after "come back here"; the opening no longer previews the handoff, which the description and "The handoff" carry.
