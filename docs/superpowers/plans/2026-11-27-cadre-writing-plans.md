# cadre:writing-plans Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** cadre gains `cadre:writing-plans`, one skill that plans one pull request through `superpowers:writing-plans`: one repo's part of a Cadre milestone, a spec not tracked in Cadre once it is registered, or requirements with no spec. `milestone.md` step 5 hands over to it. cadre 0.34.0 → 0.35.0.

**Architecture:** a new `plugins/cadre/skills/writing-plans/SKILL.md`. Steps 5 and 6 of "Start a milestone" in `milestone.md` move into it; steps 1 to 4 stay and hand over to it. "What to plan" sorts the request into four cases: the handover from step 5, a Cadre milestone, an untracked spec, requirements. Named for a milestone, the skill runs the cadre skill's checks and only steps 1 to 4 of "Start a milestone", then comes back. An untracked spec goes to "Create a project"; requirements that need more than one pull request go to `cadre:brainstorming`. Both come back to plan milestone 1 from "A Cadre milestone" step 2. The increment rules are named here and defined once, in "What a milestone is" in the brainstorming skill.

**Tech Stack:** Markdown skills, Minitest (`plugins/cadre/test/plugin_test.rb`).

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, "`cadre:writing-plans`" and Increment 3 only. PR title: `Cadre marketplace move (3/8): cadre:writing-plans`.

**Skills to load:** `superpowers:writing-skills`, `mattpocock-skills:writing-for-agents` (wins where they disagree), `engineering-review:engineering-principles` (for the reviews), `mattpocock-skills:tdd`.

**Checks:** `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`. Each test is changed first and seen red on its own assertion, then the text.

## Global Constraints

- cadre depends on `superpowers@claude-plugins-official` alone, with no version.
- No EP ID and no "colette" in any skill file or the README.
- The skill runs only when it is named or when the `cadre` skill starts a milestone. A plain "plan this", with cadre installed, stays on `superpowers:writing-plans`.
- There is no status-lines mode: a tracked spec's status lines are ignored, and an untracked spec is registered first.
- Every plan's pull request task names `cadre:pr-description`.
- A skill file that another skill follows names its own folder and the `cadre:cadre` skill, never "this skill".
- No skill file holds a literal `git push` (`test_no_skill_file_pushes_or_commits_everything`), and a backticked `a:b` is a skill call (the call list).
- The README cadre bullet stays at or under 70 words.
- Release: 0.35.0 in `plugin.json`, `marketplace.json` and `test_marketplace_lists_cadre_last_at_the_plugin_version`.
- Evals cannot run on this Mac: each moved case is recorded as not measured.

## Review Focus

- Named directly for a milestone, the skill still pulls the spec, finds this repo's part, sets up the worktree and commits the spec copy before planning; a stop in those steps stops the planning (Task 1; dry run 1).
- Handed over from step 5, it runs neither the cadre checks nor steps 1 to 4 a second time, and nothing loops back into the `cadre` skill (Task 1; dry run 1b).
- An earlier milestone, by its place in `milestones` and not its number, that isn't merged is named before planning, with a question (Task 2).
- An untracked spec is registered before anything is planned, then milestone 1 is planned (Task 3; dry runs 2 and 2b).
- One-pull-request requirements get a plan with no spec file and no Cadre line (Task 4; dry run 3a).

---

### Task 1: the skill plans a Cadre milestone, and step 5 hands over to it

**Files:**
- Create: `plugins/cadre/skills/writing-plans/SKILL.md`
- Modify: `plugins/cadre/skills/cadre/milestone.md` ("Start a milestone" steps 5 and 6), `plugins/cadre/skills/cadre/skills.md` (opening, "Read the table", "Load what the work needs", "Draft a Skills table" step 6), `plugins/cadre/skills/cadre/SKILL.md` (the skills.md router line), the spec's "`cadre:writing-plans`" section (the final-review bullet, David's 2026-11-27 choice)
- Test: `plugins/cadre/test/plugin_test.rb`

**Interfaces:**
- Produces: `cadre:writing-plans` with `## Before you start`, `## What to plan`, `## A Cadre milestone` (steps 1 Find the milestone, 2 Steps 1 to 4, 3 Earlier milestones, 4 Re-check, 5 Plan), `## Run superpowers writing-plans`. Tasks 2 to 4 add `## A spec not tracked in Cadre`, `## Requirements with no spec`, `## One pull request`, and grow the heading-order test.

- [ ] **Step 1: Change the tests**
  - New `WritingPlansTest` (includes `Sections`, reads `plugins/cadre/skills/writing-plans/SKILL.md`):
    - `test_frontmatter_names_the_skill_and_when_it_runs`: keys `name` and `description` only; `name: writing-plans`; the description exactly `Cadre planning, which plans one pull request at a time for a Cadre milestone or for requirements. Use only when the person names it ("cadre:writing-plans", "cadre's planning"), or when the cadre skill calls it from "Start a milestone".`
    - `test_the_opening_says_it_plans_one_pull_request_at_a_time`: the opening, exactly.
    - `test_its_sections_come_in_order`: the four headings above.
    - `test_it_stops_when_superpowers_writing_plans_is_missing`, `test_it_says_what_it_chose_and_why`, `test_it_checks_the_cli_and_the_sign_in_for_cadre_work` (as `BrainstormingTest` pins them, with "the planning stops too", for "A Cadre milestone" and "A spec not tracked in Cadre" only).
    - `test_what_to_plan_takes_the_first_case_that_fits`: the handover case ("handed you its spec copy's path", "go to step 3 of \"A Cadre milestone\""), the milestone case (`<slug>/<n>`, a project, a spec tracked in Cadre), the spec case, the requirements case, "ask the person what to plan", and the handover case first.
    - `test_it_finds_the_milestone_to_plan`: "its increment `<i>` is milestone `<slug>/<i>`", "whose `current` is true", "and say so", "ask the person which".
    - `test_named_for_a_milestone_it_runs_start_a_milestone_first`: "Run only steps 1 to 4 of \"Start a milestone\" in [milestone.md](../cadre/milestone.md)", "then come back here", "the planning stops too", the done-criterion.
    - Moved from `SkillTest`, on `## A Cadre milestone` and `## Run superpowers writing-plans`: `PLAN_LINE` once, its app variant, "uses the `cadre:cadre` skill", "each task names the skills it needs (from the table when the repo has one), since a subagent executing it loads only those", "as [skills.md](../cadre/skills.md) says", "one plan and one pull request", "the spec-coverage check covers that part alone", the pull request task naming `cadre:pr-description`.
    - `test_the_plan_pushes_and_opens_its_pull_request` ("never a local merge"), `test_later_review_rounds_review_only_the_new_commits` (`git diff <last-reviewed-sha>..HEAD`, "standing decision", where each round is recorded), `test_execution_stays_with_superpowers`.
    - `refute_includes skill, "this skill's folder"`.
  - `SkillTest`:
    - New `test_step_5_hands_over_to_cadre_writing_plans`: `start_section` holds `` `cadre:writing-plans` `` and "the spec copy's path", and no `REQUIRED SKILL`, no "Execute the plan" and no `6. `.
    - `test_it_starts_a_milestone_with_one_plan_and_one_pull_request_per_repo` drops `` `superpowers:writing-plans` `` and `Cadre: <slug>/<n>`; `test_it_starts_a_milestone_from_its_app_steps` and it keep "one pull request" from step 2, not "one plan and one pull request".
    - `test_each_task_names_its_skills_for_the_subagent_that_executes_it`, `test_the_plan_says_it_is_tracked_in_cadre` and the step-5 halves of `test_the_pull_request_lists_what_a_deploy_needs_first` and `test_each_plan_task_names_the_skills_it_needs` move to `WritingPlansTest`.
    - `test_it_reads_the_table_with_the_script`: `<skills.md's folder>`; `test_each_plan_task_names_the_skills_it_needs`: `Load every row whose When fits the work, before planning.`; `test_each_section_says_where_to_go_next`: "while planning"; new `refute_includes` of "this skill" in `milestone.md` and `skills.md`.
    - `test_skill_files_call_only_superpowers_skills_and_cadre_itself`: the list gains `cadre:writing-plans`; the comment gives its reason: cadre's own skill, which "Start a milestone" calls.
- [ ] **Step 2: Run the checks.** Expected: every `WritingPlansTest` errors on the missing file; each changed `milestone.md`, `skills.md` and `SKILL.md` test is red on its own assertion.
- [ ] **Step 3: Create the file with its frontmatter alone. Run.** Expected: each `WritingPlansTest` is red on its own assertion.
- [ ] **Step 4: Write the text**
  - `SKILL.md`: the frontmatter; the opening (one pull request at a time; later milestones once this one has shipped, with what it taught); `## Before you start`; `## What to plan`; `## A Cadre milestone` steps 1, 2 and 5; `## Run superpowers writing-plans`.
  - `milestone.md` step 5: `Plan this repo's part with the `cadre:writing-plans` skill: load it, and hand it the spec copy's path, this repo's part and, for one app's pull request, its app.` Step 6 goes.
  - `skills.md`: "whenever you plan, as the `cadre:writing-plans` skill says"; `<skills.md's folder>`; "fits the work"; "while planning". `SKILL.md`: the skills.md line "when planning".
  - The spec's "`cadre:writing-plans`" section gains the final-review bullet.
- [ ] **Step 5: Run the checks.** Expected: green.
- [ ] **Step 6: Commit** `cadre:writing-plans plans a Cadre milestone`.

### Task 2: a milestone is checked against what earlier milestones taught

**Files:** `SKILL.md` (`## A Cadre milestone` steps 3 and 4, `## One pull request`, the size rule), the test file.

- [ ] **Step 1: Write the failing tests**
  - `test_it_asks_before_planning_after_an_unmerged_milestone`: `cadre status <slug> --json`, "an entry before `<n>`'s in `milestones`", "`state`", "neither `can_deploy` nor `deployed`", "ask whether to plan anyway".
  - `test_it_rechecks_the_milestone_against_the_code_as_it_is_now`: "Read the code as it is now, without asking", "as \"One pull request\" says", "\"Update a milestone's spec\" in [project.md](../cadre/project.md)", "pull and commit the spec copy again, as steps 1 and 4 of \"Start a milestone\" do".
  - `test_one_pull_request_ships_one_milestone`: `## One pull request` names "one feature", "the smallest step", "its consumers named", links "\"What a milestone is\" in [the brainstorming skill](../brainstorming/SKILL.md)", and holds "counted without tests and docs", "aim for 10", "20 or fewer".
  - `test_a_plan_above_20_code_files_says_kept_whole_or_why_or_stops`: the size rule as one string, from "When the plan's file structure holds more than 20 code files" to "take requirements on to `cadre:brainstorming`, as \"Requirements with no spec\" says."
  - The order test gains `## One pull request`.
- [ ] **Step 2: Run.** Expected: red on each.
- [ ] **Step 3: Write** the two steps, `## One pull request` and the size rule.
- [ ] **Step 4: Run.** Expected: green.
- [ ] **Step 5: Commit** `cadre:writing-plans checks a milestone against the earlier ones`.

### Task 3: a spec not tracked in Cadre is registered first

**Files:** `SKILL.md` (`## A spec not tracked in Cadre`), the test file.

- [ ] **Step 1: Write the failing test** `test_an_untracked_spec_is_registered_before_milestone_1_is_planned`: "\"Create a project\" in [project.md](../cadre/project.md) from step 1", `` `cadre:brainstorming` ``, "milestone `<slug>/1`", "from its step 2"; `## What to plan` says a tracked spec's status lines are ignored. The order test gains the heading.
- [ ] **Step 2: Run.** Expected: red.
- [ ] **Step 3: Write** the section.
- [ ] **Step 4: Run.** Expected: green.
- [ ] **Step 5: Commit** `cadre:writing-plans registers an untracked spec first`.

### Task 4: requirements with no spec

**Files:** `SKILL.md` (`## Requirements with no spec`), the test file.

- [ ] **Step 1: Write the failing test** `test_requirements_are_one_pull_request_or_a_brainstorm_first`: "Read the code without asking", "and why", "no spec file", "no `Cadre:` line", "load `cadre:brainstorming`", "come back here and plan milestone `<slug>/1`". The order test gains the heading.
- [ ] **Step 2: Run.** Expected: red.
- [ ] **Step 3: Write** the section.
- [ ] **Step 4: Run.** Expected: green.
- [ ] **Step 5: Commit** `cadre:writing-plans plans requirements with no spec`.

### Task 5: dry runs

Fresh subagents read only `plugins/cadre/skills/writing-plans/SKILL.md` in this worktree and the cadre files it links, by their worktree paths: the installed cadre is 0.34.0, with the old step 5, so they never load a `cadre:*` skill with the Skill tool. They run no `cadre` or `git` command that writes; the brief gives each stubbed output. Each stops at the args it would hand `superpowers:writing-plans` and reports them. Briefs name no authoring skill and forbid `colette:writing-plans`.

- [x] 1. **A Cadre milestone, named.** "plan wish-reminders/2 with cadre:writing-plans" in `shop-api`, milestone 1 `in_review`. Passes when the run checks superpowers, says what it chose, runs the three cadre sections, runs only steps 1 to 4 of "Start a milestone", asks about milestone 1, reads the Skills table, and hands over the spec copy's path, the header line, the skills per task, the size rule, the delta review rounds and a PR task naming `cadre:pr-description` that never merges locally.
- [x] 1b. **Handed over from step 5.** Passes when no second `cadre whoami`, no second spec pull and no return into the `cadre` skill.
- [x] 1c. **A tracked feature spec, no number.** Passes when it takes the `current` milestone and says so.
- [x] 2. **An untracked spec with Increments.** Passes when it follows "Create a project" from step 1 and stops at step 6's playback, with no plan written.
- [x] 2b. **The return.** Starts from a stubbed `cadre project create` answer. Passes when it plans `<slug>/1` from "A Cadre milestone" step 2.
- [x] 2c. **An untracked spec without Increments.** Passes when "Create a project" step 1 loads `cadre:brainstorming`.
- [x] 3a. **Requirements, one pull request.** "cadre:writing-plans: members can archive a wish" in a small repo. Passes when it says one pull request and why, and hands over no spec file and no Cadre line.
- [x] 3b. **Requirements across two repos.** Passes when it loads `cadre:brainstorming`.
- [x] 4. **Not asked.** Each subagent gets the installed skills' descriptions, the new one included, and one request. "plan this: members can archive a wish", five fresh runs, and "plan docs/superpowers/specs/2026-10-19-archive-wishes-design.md" on an untracked spec pass on `superpowers:writing-plans`; "use cadre's planning for wish reminders" passes on `cadre:writing-plans`; a spec with the Cadre tracking line passes on `cadre:cadre`.

A failed run means test first, then text. colette's eval cases, none run, each recorded as not measured in the PR: plans-the-next-increment (1), colette-spec-plans-with-colette (4, the tracked spec), plain-spec-plans-with-superpowers (4), spec-without-increments (2c), plans-small-requirements (3a), big-requirements-get-increments (3b). brainstorm-hands-off-to-writing-plans is dropped: `cadre:brainstorming` hands over to "Create a project".

### Task 6: release 0.35.0

**Files:** `plugins/cadre/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, the test file.

- [ ] **Step 1: Change the tests:** `"0.35.0"`; the bullet is exactly:

  ```markdown
  - **cadre** — runs Cadre from Claude Code: it starts milestones and links their pull requests, connects repos to Fly, Vercel or the app stores, deploys them and writes Skills tables. [`cadre:brainstorming`](plugins/cadre/skills/brainstorming/SKILL.md) brainstorms a feature into a Cadre project; [`cadre:writing-plans`](plugins/cadre/skills/writing-plans/SKILL.md) plans a milestone's pull request; [`cadre:pr-description`](plugins/cadre/skills/pr-description/SKILL.md) sets the standard for PR descriptions. It installs the `cadre` CLI and signs you in; cadre installs `superpowers` from `claude-plugins-official` with it. [The skill](plugins/cadre/skills/cadre/SKILL.md).
  ```

  70 words; the cap stays.
- [ ] **Step 2: Run.** Expected: red on the version and the bullet.
- [ ] **Step 3:** both manifests at `0.35.0`; the bullet as above.
- [ ] **Step 4: Run.** Expected: green.
- [ ] **Step 5: Commit** `Cadre 0.35.0: cadre:writing-plans, one pull request planned at a time`.

## Dry runs, results

Every run passed. 1, 1b and 1c stop at the args to `superpowers:writing-plans` or at the milestone said; 1b runs no second sign-in, spec pull or cadre skill. 2 stops at "Create a project" step 6's playback; 2b plans `gift-wrap/1` from step 2 with no check run twice; 2c reaches `cadre:brainstorming` from "Create a project" step 1. 3a runs no `cadre` command and hands over no spec file and no Cadre line; 3b stops at `cadre:brainstorming`. Routing: the three one-line "plan this" runs picked `superpowers:brainstorming`, superpowers' own first step for a one-line feature; two "plan this" runs with settled requirements and the untracked spec picked `superpowers:writing-plans`; "use cadre's planning" picked `cadre:writing-plans`; the tracked spec picked `cadre:cadre`.

Fixed from them: step 5 hands over the milestone `<slug>/<n>` with the spec copy's path; the question about an unmerged milestone says this branch lacks its changes; the code read without asking is this repo's.

Left as they are, outside this increment: `milestone.md` step 3 names no command for "`<branch>` exists"; "Create a project" step 3 adds the tracking line before step 6's approval and leaves it uncommitted in the main checkout, so a new worktree lacks it.

## Finishing

1. One full rule-by-rule `engineering-principles` review and one `writing-for-agents` review of `git diff origin/main...HEAD`; fix every finding, Minors included. Each later round reviews only `git diff <last-reviewed-sha>..HEAD`, with every earlier ruling in its brief as a standing decision, and is recorded below. Stop when a round is clean.
2. Push and open the PR, described to `plugins/cadre/skills/pr-description/SKILL.md`. David merges.
3. Set Increment 3's status line to `- [x] PR #<n>` in the spec on the same branch, and push.

## Fable's review, folded in

- The handover from step 5 is its own case in "What to plan", so neither the cadre checks nor steps 1 to 4 run twice; the paths that come back to plan milestone 1 enter "A Cadre milestone" at step 2.
- A stop inside steps 1 to 4 stops the planning; a re-check that updates the spec pulls and commits the copy again.
- "Earlier" is an entry's place in `milestones`, which lists them in project order, not by number; `<n>` is the one named, else `current`, said, else asked.
- The size rule says where a plan that could be smaller goes; the spec-coverage check covers this repo's part alone.
- Tests for the opening, the cases and the stale "this skill" lines; the two start-a-milestone tests the move breaks; the order test grows per task; the README bullet is pinned whole.
- The dry runs cover the return to plan milestone 1, a spec without Increments, a plain "plan this spec", and a tracked spec; they read the worktree's files, not the installed 0.34.0 plugin, and stop at the args handed to superpowers.
- The increment rules are named in the pointer and defined in the brainstorming skill; the delta-review rule stays, recorded in the spec as David's 2026-11-27 choice.

## Reviews, folded in

### Round 1: `origin/main...b08e463`, full branch

engineering-principles (2 Important, 3 Minor) and writing-for-agents (3 Important, 4 Minor), all fixed:

- The earlier-milestone check reads this repo's step and its pull requests' `status` (`merged`, `stranded` or `deployed`), not the milestone's `state`, which Cadre sets from the next step.
- "Before you start" step 4 follows the case's section, so the cadre checks run before a named milestone's steps 1 to 4; the handover lists all it hands over, and isn't told back to the person.
- Step 4 estimates the code files, proposes a split or a spec change, says how each lands (a new milestone, the narrowed spec, the copy pulled again) and ends when what was proposed is settled; the size rule reuses it.
- The plan holds a final review task where each round records what it reviewed and its rulings.
- "One pull request" ships one increment, as "What a milestone is" defines a milestone; the rules handed to superpowers name the given part, not "this skill"; "the size rule … stops the plan" replaces "the planner".
- `skills.md` step 6 commits on the milestone's branch while planning a milestone, otherwise on the branch the person names; the router says "when `cadre:writing-plans` plans".
- Trailing spaces gone from the test file.

### Round 2: `b08e463..a3b7ff2`

engineering-principles (4 Minor, one note) and writing-for-agents (2 Important, 3 Minor), all fixed:

- A declined split no longer loops: the part is planned as it is, and the plan says why it can't be smaller; the size rule proposes the split through step 4, then plans again from step 5.
- A split's new milestone goes right after `<slug>/<n>`; step 4 lands a split and a spec change each in their own words, then runs steps 1, 2 and 4 of "Start a milestone" again, so this repo's part is found again.
- `stranded` no longer counts as merged: its commits never reach the default branch (`pull_request.ex`). A factual correction of round 1's list, not a change of its rule.
- The given part names one app's plan; `skills.md` step 6 asks which branch when the person names none.
- Two tests renamed or split so their names match what they pin; "What to plan" is pinned to hold no routing.

### Round 3: `a3b7ff2..862caeb`

engineering-principles (1 Important, 2 Minor) and writing-for-agents (1 Important, 3 Minor), all fixed:

- The size rule skips its stop when the person kept the part whole at step 4, and that plan says the person kept it whole: the declined split no longer comes round again.
- Step 4's re-run is "only steps 1, 2 and 4 … and come back here", and a stop in it stops the planning; one sentence makes either spec change through "Update a milestone's spec".
- The test's stray `].each` is back on its last element.

### Round 4: `862caeb..70e794d`

engineering-principles: clean. writing-for-agents (1 Important, 2 Minor), all fixed:

- The size rule opens on the kept-whole case, where the plan says the person kept it whole; otherwise the plan says why it can't be smaller, or the rule stops. Step 4 is named with its section on first mention.
- "Either spec edit, the narrowing or the spec change" goes through "Update a milestone's spec"; the split's new milestone stays with "Change a project".

### Round 5: `70e794d..3afeca7`

engineering-principles (2 Minor) and writing-for-agents (1 Important), all fixed:

- The size rule nests both branches under its 20-file trigger, so a plan of 20 code files or fewer neither explains nor stops; the test pins the two branches as one string, in order, under a name that says all three outcomes.

### Round 6: `3afeca7..a7723f4`

engineering-principles (2 Minor) and writing-for-agents (1 Minor), all fixed: the size-rule test pins the whole rule, the requirements clause included, as one string; Task 2's bullet describes that test.
