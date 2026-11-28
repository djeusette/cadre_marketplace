# Break check (4/5): plans run the break check — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `cadre:writing-plans`, in a repo whose Skills table lists `engineering-review:break-check`, checks that skill and Ruby 3.2 up front and writes the break check into the plan; a repo without the row plans as today.

**Architecture:** Two text changes to `plugins/cadre/skills/writing-plans/SKILL.md`: a step in "Before you start", and a "The break check" rule among the rules "Run superpowers writing-plans" puts on top of `superpowers:writing-plans`. Both open on the condition "the Skills table … lists `engineering-review:break-check`", and a test pins that every mention of that skill in cadre's skill files sits in that condition. cadre 0.35.1 → 0.36.0.

**Tech Stack:** Markdown skill text; Minitest (`plugins/cadre/test/plugin_test.rb`).

**Spec:** `docs/superpowers/specs/2026-11-27-shared-break-check-runner-design.md`, "The plans (increment 4)" and "Increment 4". The flags come from this checkout's `plugins/engineering-review/skills/break-check/SKILL.md` (0.24.0), which added the base to `--table`; the spec's `--table` predates it.

**Reviewed** by Fable before the build: 1 Critical, 6 Important, 7 Minor, folded in.

## Global Constraints

- cadre's skills cite no EP IDs and never write "colette" (`test_skill_files_call_only_superpowers_cadre_and_a_listed_break_check`, `test_no_skill_file_names_colette`).
- `cadre` never depends on `engineering-review`: `cadre:writing-plans` names `engineering-review:break-check` only for a repo whose Skills table lists it. `plugin.json`'s `dependencies` stay `["superpowers@claude-plugins-official"]`.
- The cadre skill states the steps in its own words, without EP IDs.
- Ruby 3.2 or later on the machine that runs breaks.
- Every merge to `main` is a release: cadre's version moves in `plugins/cadre/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` and `test_marketplace_lists_cadre_at_the_plugin_version`.
- `plugin_test.rb` pins cadre's wording: change the test first, watch it go red, then the text.
- `AGENTS.md`'s five Checks green before each commit.

## Review Focus

1. **A repo without the row.** Nothing about the break check reaches its plan, and its "Before you start" asks for no Ruby. Pinned by the conditional-mention test (Task 1) and dry run C (Task 3).
2. **The row is listed but the plugin isn't loadable, or `ruby` is 2.6.** Planning stops before any case section runs (in the handed-over case, after the milestone's steps 1 to 4 already ran), naming the Install command or the Ruby to put first on `PATH`. Pinned in Task 1.
3. **A test the final break check adds goes unreviewed.** A commit the break check makes after a clean round is reviewed by another round, and the final review ends only when a break check after a clean round commits nothing. Pinned in Task 2.
4. **The table in the PR is stale or empty.** The PR task runs `--table <base>` itself, after the final review, and adds the Break checks part only when the table has a row. Pinned in Task 2.
5. **A repo with the row and no `.break-check.json`.** The plan's first task writes it, checked by one caught break per profile of a branch that already has a test, before any task's break check needs it. Pinned in Task 2, exercised by dry run B.

---

### Task 1: "Before you start" checks the break-check skill and Ruby

**Skills:** `mattpocock-skills:writing-for-agents`, `superpowers:writing-skills`, `engineering-review:engineering-principles`, `mattpocock-skills:tdd`.

**Files:**
- Modify: `plugins/cadre/skills/writing-plans/SKILL.md` ("## Before you start")
- Modify: `plugins/cadre/test/plugin_test.rb` (`WritingPlansTest`, `SkillTest`'s skill-call test, `test_marketplace_lists_cadre_at_the_plugin_version`)
- Modify: `plugins/cadre/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (version `0.36.0`)

- [ ] **Step 1: Write the failing tests**

In `WritingPlansTest`:

```ruby
def test_it_checks_the_break_check_skill_and_ruby_when_the_skills_table_lists_it
  ["2. When the Skills table in the repo's root `AGENTS.md` lists `engineering-review:break-check`, check that the skill is among your available skills and that `ruby --version`, run from the repo's root, prints Ruby 3.2 or later: the plan runs its break check.",
   "When the skill is missing, tell the person its row's Install command.",
   "When Ruby is missing or older, tell the person to put Ruby 3.2 or later first on `PATH`.",
   "Either way, stop."].each { |text| assert_includes before_you_start, text }
  assert_operator before_you_start.index("`engineering-review:break-check`"), :<, before_you_start.index("[the cadre skill]")
end
```

In `test_before_you_start_routes_to_the_case_section` the routing step becomes `5. Follow the section named for the case; …`. In `test_marketplace_lists_cadre_at_the_plugin_version`, `"0.35.1"` becomes `"0.36.0"`.

`test_skill_files_call_only_superpowers_skills_and_cadre_itself` is renamed `test_skill_files_call_only_superpowers_cadre_and_a_listed_break_check`; its list gains `engineering-review:break-check` (after the four `cadre:` entries, before `superpowers:brainstorming`), its comment says cadre names it only for a repo whose Skills table lists it, and it pins that every mention of the plugin is conditional:

```ruby
mentions = skill_files.sum { |path| File.read(path).scan("engineering-review").size }
conditional = File.read(File.join(PLUGIN, "skills", "writing-plans", "SKILL.md")).scan(/When the (?:Skills table in the repo's root `AGENTS\.md`|repo's Skills table) lists `engineering-review:break-check`/).size
assert_equal mentions, conditional
```

- [ ] **Step 2: Run them red**

Run: `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb -n "/break_check_skill_and_ruby|routes_to_the_case|cadre_at_the_plugin_version|a_listed_break_check/"`
Expected: 4 failures.

- [ ] **Step 3: Write the step and bump the version**

Insert the tested text as step 2 of "## Before you start", after the `superpowers:writing-plans` check, and renumber the later steps 3 to 5. Set `"version": "0.36.0"` in `plugin.json` and in cadre's `marketplace.json` entry (edit as text: `JSON.pretty_generate` reflows the inline arrays).

- [ ] **Step 4: Run the Checks green**

Run each of `AGENTS.md`'s five Checks. Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/cadre .claude-plugin/marketplace.json
git commit -m "feat(cadre): writing-plans checks the break-check skill and Ruby when the Skills table lists it"
```

### Task 2: the plan runs the break check

**Skills:** as Task 1.

**Files:**
- Modify: `plugins/cadre/skills/writing-plans/SKILL.md` ("## Run superpowers writing-plans", step 2)
- Modify: `plugins/cadre/test/plugin_test.rb` (`WritingPlansTest`)

- [ ] **Step 1: Write the failing test**

In `WritingPlansTest`:

```ruby
def break_check_rule = run_section[/^   - \*\*The break check\.\*\* .*?(?=^   - \*\*The pull request task\.\*\*)/m] || flunk("no break check rule")

def test_the_plan_runs_the_break_check_when_the_skills_table_lists_it
  ["   - **The break check.** When the repo's Skills table lists `engineering-review:break-check`, the plan proves a test catches each branch it adds or changes with that skill's break check, run as that skill says by a task that lists the skill among its skills:\n",
   "     - **The first task**, when the repo's root holds no `.break-check.json`, writes it and checks it with one caught break per profile of a branch that already has a test.\n",
   "     - **Each task that changes code**, once its tests are green and before its commit, runs the break check on its lines in the session that wrote them.\n",
   "     - **The final review task**, once a round is clean, runs `--stale --replay`, then `--uncovered <the pull request's base commit>`, then a break for each branch on the lines it lists. When this commits a test or a fix, another round reviews that delta and the break check runs again. The final review ends when a break check after a clean round commits nothing.\n",
   "     - **The pull request task** runs `--table <the pull request's base commit>`; when the table has a row, it is the description's Break checks part.\n"].each { |text| assert_includes break_check_rule, text }
end
```

- [ ] **Step 2: Run it red**

Run: `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb -n test_the_plan_runs_the_break_check_when_the_skills_table_lists_it`
Expected: 1 failure ("no break check rule").

- [ ] **Step 3: Write the rule**

In step 2 of "## Run superpowers writing-plans", add "The break check" as a bullet between "The final review" and "The pull request task", in the tested words: its condition, then one sub-bullet per kind of task (written as one paragraph first; `mattpocock-skills:writing-for-agents` split it: nine sentences, "as that skill says" three times, and dry run B could not tell which tasks "Each task named here" meant).

- [ ] **Step 4: Run the Checks green**

Run each of `AGENTS.md`'s five Checks. Expected: all pass (the conditional-mention test now counts 2 mentions, 2 conditional).

- [ ] **Step 5: Commit**

```bash
git add plugins/cadre
git commit -m "feat(cadre): a plan runs the break check when the Skills table lists it"
```

### Task 3: dry-run the skill

**Skills:** `mattpocock-skills:writing-for-agents`, `superpowers:writing-skills`.

Three subagents, each told to follow this checkout's `plugins/cadre/skills/writing-plans/SKILL.md` (not the installed cadre) for "Requirements with no spec", to read this checkout's `plugins/engineering-review/skills/break-check/SKILL.md` for the break check (the installed engineering-review is older), to write the plan to the scratchpad, and to create no branch, worktree or commit and execute nothing:

- [ ] **A — row and `.break-check.json`:** `~/Code/cadre`, a one-branch change (for example a guard in an existing function). Expected: "Before you start" checks the skill and Ruby; no task writes `.break-check.json`; each code task names the skill and runs the break check after green; the final review runs `--stale --replay`, `--uncovered <base>`, the breaks, and loops on a commit; the PR task runs `--table <base>`.
- [ ] **B — row, no `.break-check.json`:** a scratch git repo with an `AGENTS.md` whose Skills table lists the row, one Ruby file and its Minitest test. Expected: as A, and the first task writes `.break-check.json` with one caught break as its check.
- [ ] **C — no row:** this repo (`cadre_marketplace`), a one-line change to a cadre skill. Expected: no Ruby check, no break check anywhere in the plan.

Record each outcome here. A failure is fixed in Task 1 or 2's text, test first, and the dry run reruns.

Outcomes:
- A (a 403 joins `[400, 401]` in `google_play.ex`): passed. Ruby 3.4.4 checked from cadre's root; no `.break-check.json` task; every task lists the skill; the code task breaks each guard value after green; the final review runs the three steps after a clean round, loops on a commit and ends on a break check that commits nothing; the PR task runs `--table <base>`. It took `--partition`, the rerun until `0 stale` and the branches outside the watched paths from the break-check skill, as "run as that skill says" asks.
- B (`Shelf#add` refuses a duplicate): passed. Task 1 writes `.break-check.json` and `.gitignore`'s `.breaks/`, checked by `@books.size >= @capacity` → `> @capacity` caught. Flagged "Each task named here" as unclear: the rule was split into sub-bullets, and B reran on the new text.
- C (a sentence in `cadre:pr-description`, in this repo's main checkout): passed. No row, no `ruby --version`, and `rg "break.check|--stale|--uncovered|--table"` hits only an `AGENTS.md` Check the plan copies.

### Task 4: final review

**Skills:** `engineering-review:engineering-principles`, `mattpocock-skills:writing-for-agents`.

- [ ] **Step 1: Review rounds.** Round 1 reviews the whole branch (`git diff main...HEAD`); each later round reviews only `git diff <last-reviewed-sha>..HEAD`, its brief listing every earlier ruling as a standing decision. Two lenses per round: engineering-principles rule by rule, and writing-for-agents. Each round fixes what it finds and records here, in one form, `Round <n> (<sha>): <lens> (<n> Minor), fixed: <file> says <what>.` or `Round <n> (<sha>): clean on both.`; that form is passed to the reviewer as a standing decision. The review ends when a round is clean on both.
Record:

- Round 1 (b33ca1e): engineering-principles (4 Minor), writing-for-agents (4 Important, 5 Minor), fixed: writing-plans' SKILL.md says the missing skill is named as skills.md's "Check each row" says, stops inside each failure, points each break-check step at that skill's section, ends the final review in one place, covers a repo with a runner of its own, and leaves the Break checks part to `cadre:pr-description`; the plan names the renamed test.

- [ ] **Step 2: No break check.** This repo's Skills table has no break-check row, and the change adds or changes no runner branch, so the PR has no Break checks part.

### Task 5: pull request

**Skills:** `cadre:pr-description`.

- [ ] **Step 1:** Push the branch and open the PR titled `Break check (4/5): plans run the break check`, described to `cadre:pr-description`, with no Break checks part. It says the plans' `--table <base>` needs engineering-review 0.24.0 or later. Never a local merge.
- [ ] **Step 2:** In the spec, Increment 4's status line becomes `- [x] PR #<n>` with the number Step 1 got; commit and push.
- [ ] **Step 3:** CI green. Append the outcome and gotchas to `move-progress.md` in the `local_5986f0d0-…` side-session notes folder.
