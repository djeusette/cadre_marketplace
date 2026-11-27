# engineering-review uses cadre:pr-description Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `pr-description` leaves `engineering-review`. The review companion and EP-F5 point at `cadre:pr-description`, and installing `engineering-review@cadre` installs `cadre`. engineering-review 0.21.0 → 0.22.0; cadre stays 0.35.1.

**Architecture:** `plugins/engineering-review/skills/pr-description/` is deleted. Every file that names it names `cadre:pr-description` instead, and `plugin.json`'s `dependencies` gain `cadre` by bare name, which resolves in this marketplace. The Claude Code docs show only bare names in an agent's `skills:` list and skip a missing entry with a warning in the debug log. They do not say that the list accepts another plugin's skill. So `agents/review-companion.md` drops `pr-description` from `skills:` and loads `cadre:pr-description` with the `Skill` tool.

**Tech Stack:** Markdown skills, Python `unittest` (engineering-review), Minitest (cadre, the bump check).

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, "`engineering-review` in the cadre marketplace" (the switch) and Increment 5 only. PR title: `Cadre marketplace move (5/8): engineering-review uses cadre:pr-description`.

**Skills to load:** `superpowers:writing-skills`, `mattpocock-skills:writing-for-agents` (wins where they disagree), `engineering-review:engineering-principles`, `mattpocock-skills:tdd`.

**Code files:** 3: `.claude-plugin/marketplace.json`, `plugins/engineering-review/.claude-plugin/plugin.json`, `plugins/engineering-review/agents/review-companion.md`. The spec's fourth, `check_plugin.py`, is listed "if a check names `pr-description`". None does: `AGENT_SKILLS` holds the four skills that stay. Task 7 corrects the spec's line.

**Checks**, all green before every commit:

- `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`
- `python3 -m unittest discover -s plugins/engineering-review/scripts -p 'test_*.py'`
- `python3 plugins/engineering-review/scripts/check_plugin.py plugin plugins/engineering-review`, which prints `OK`
- `ruby test/check_version_bumps_test.rb`
- before the PR: `ruby script/check_version_bumps.rb origin/main` prints `OK`; `~/.local/bin/claude plugin validate .` and `… validate plugins/engineering-review` pass

## Global Constraints

- Edit nothing in colette-club. Its `engineering-review` is frozen.
- No file under `plugins/cadre/` changes, so cadre does not bump. cadre still depends only on `superpowers@claude-plugins-official`.
- `engineering-review`'s `dependencies` are `["security-audit", "cadre"]`, both bare names.
- No `engineering-review@cadre` install line in README, and no Skills rows or settings for it, before increment 6.
- No file under `plugins/engineering-review/skills/` or `agents/` names the skill as a bare `pr-description` or as `engineering-review:pr-description`. Eval case names (`pr-description-*`) and the draft-file suffix `-pr-description` are not skill names, and they stay.
- `test_check_plugin.py` keeps every guard it held on the standard. Its tests that read the old skill read cadre's copy instead (`PR_STANDARD`), since engineering-review's files delegate to that copy. They drop only the EP IDs, which cadre's skill never cites. Two phrases change to cadre's words: the dropped Break checks row, and the Deploy line's template.
- Evals can't run on David's Mac: each changed case is recorded as not measured. The description check and the agent's load are dry-run by subagent instead (Task 5).
- Commit subjects follow the repo: `Cadre marketplace move: …`, and the release commit `engineering-review 0.22.0: …`.

## Review Focus

- A runtime or session where `cadre` is not installed: the companion reports `cadre:pr-description` as not loaded and raises no description finding as checked. Item 9's existing rule covers it (Task 2), and Task 5's agent dry run exercises it.
- The `review-companion` agent run as a subagent: no `skills:` entry points at a missing skill, and its body has it load `cadre:pr-description` with `Skill` (Task 3; Task 5's agent dry run).
- A description with cadre's app form, `Cadre: <slug>/<n> <app>`, raises no Cadre line finding (Task 4).
- A reader of review-passes or review-report who follows a cited section ("Pictures", "Rewriting a description", "Not essential", the title's sequence signals) finds it in cadre's skill (Task 2, `test_the_sections_the_review_cites_are_in_cadres_pr_standard`).
- A fresh install of `engineering-review@cadre` brings `cadre`, `security-audit` and, through cadre, `superpowers`. An update from 0.21.0 adds `cadre` (Task 6).

---

### Task 1: engineering-review depends on cadre

**Files:**
- Create: this plan
- Modify: `plugins/engineering-review/scripts/test_check_plugin.py` (`test_the_plugin_depends_on_the_pinned_security_audit_skill`), `plugins/engineering-review/.claude-plugin/plugin.json`

- [ ] **Step 1:** Rename the test to `test_the_plugin_depends_on_cadre_and_the_pinned_security_audit_skill`. It asserts `plugin["dependencies"] == ["security-audit", "cadre"]` and that marketplace.json's `cadre` entry has `source` `./plugins/cadre`. Run it: red.
- [ ] **Step 2:** Add `"cadre"` to `dependencies`. Run every check: green.
- [ ] **Step 3: Commit** `Cadre marketplace move: engineering-review depends on cadre` (with this plan).

### Task 2: the review skills point at `cadre:pr-description`

**Files:**
- Modify: `test_check_plugin.py`; `skills/review-companion/SKILL.md` (item 9, Runtime notes), `skills/review-passes/SKILL.md` (item 5, pass 6's behind the scenes), `skills/review-report/SKILL.md` ("The description, by role"), `skills/engineering-principles/SKILL.md` (EP-F5's last sentence), `skills/break-check/SKILL.md` (two `(pr-description)` pointers), `skills/break-check/contract.md` (`--table`'s line)

- [ ] **Step 1: Tests.**
  - New class `PrStandardTest`.
  - Its `test_no_skill_or_agent_names_the_pr_standard_by_its_old_name` checks every `.md` under `skills/` and `agents/`: none holds `` `pr-description` `` or `engineering-review:pr-description`. Each of the six files above holds `` `cadre:pr-description` ``.
  - Its `test_the_sections_the_review_cites_are_in_cadres_pr_standard` reads `plugins/cadre/skills/pr-description/SKILL.md`, which holds `\n## The title\n`, `\n## Not essential\n`, `\n## Pictures\n` and `\n## Rewriting a description\n`. It is green on arrival, so see it red once by renaming a heading in a scratch edit.
  - The assertions on engineering-review's files that quote `` `pr-description` `` now quote `` `cadre:pr-description` ``: item 5's three phrases, pass 6's scope line, `"Pictures" in`, EP-F5's part list and `` `engineering-review:pr-description` `` in the companion.
  - Run: red.
- [ ] **Step 2: Text.** Each pointer names `` `cadre:pr-description` ``. Item 9 loads four skills, then every stack skill: three from this plugin and `cadre:pr-description` from the `cadre` plugin. Its cannot-be-loaded rule covers all four. The Runtime notes list `cadre:pr-description` after this plugin's skills. EP-F5 ends "The template and what to cut are in the `cadre:pr-description` skill." Run every check: green.
- [ ] **Step 3: Commit** `Cadre marketplace move: the review points at cadre:pr-description`.

### Task 3: `pr-description` leaves engineering-review

**Files:**
- Delete: `plugins/engineering-review/skills/pr-description/`
- Modify: `agents/review-companion.md`, `test_check_plugin.py`

- [ ] **Step 1: Tests.**
  - Module constant `PR_STANDARD = PLUGIN_DIR.parent / "cadre" / "skills" / "pr-description" / "SKILL.md"`. The nine tests that read the old skill read `PR_STANDARD`, and so does `PrStandardTest`.
  - They drop the old skill's EP IDs (`EP-F5`, `EP-E5`, `EP-I5`, `EP-I3`, `elixir #59`). `test_pr_description_skill_fixes_the_title_headings_and_markers` becomes `test_the_pr_standard_fixes_the_title_headings_and_markers`, and its agent line moves to the new test below.
  - Two phrases take cadre's words: "a row that does not belong to this change is dropped," and the Deploy template line up to "what comes after the deploy".
  - Drop `pr-description` from the triggers dict of `test_a_description_names_what_the_skill_is_and_when_to_load_it_and_nothing_else`.
  - New `PrStandardTest.test_the_pr_standard_is_cadres`. `skills/pr-description` does not exist, `"  - pr-description\n"` is not in the agent, and the agent holds `` Load `cadre:pr-description` with the `Skill` tool ``.
  - Run: red on the new test only.
- [ ] **Step 2: Text.** `git rm -r` the skill. The agent drops `- pr-description` from `skills:`. Its last line gains the sentence "Load `cadre:pr-description` with the `Skill` tool before you check the pull request's title and description: it is the standard, and it comes from the `cadre` plugin." Run every check: green, `check_plugin.py` `OK`.
- [ ] **Step 3: Commit** `Cadre marketplace move: pr-description leaves engineering-review`.

### Task 4: pass 5 takes the Cadre line's forms from cadre

`cadre:pr-description` allows `Cadre: <slug>/<n> <app>` for a pull request for one app. Pass 5 still raises 🟠 unless a line "reads exactly `Cadre: <slug>/<n>`".

**Files:**
- Modify: `skills/review-passes/SKILL.md` (the Cadre line bullet), `test_check_plugin.py` (`test_the_pr_standard_requires_the_cadre_line_on_a_pr_of_a_milestone_tracked_in_cadre`)

- [ ] **Step 1:** The test asserts that the bullet holds "and no line of the description is a Cadre line in a form `cadre:pr-description` gives" and that it no longer holds "reads exactly". It also asserts that `PR_STANDARD`'s part 7 holds "or `Cadre: <slug>/<n> <app>` for a pull request for one app". Run: red.
- [ ] **Step 2:** Reword the bullet to that phrase; the rest of it stays. Run every check: green.
- [ ] **Step 3: Commit** `Cadre marketplace move: pass 5 takes the Cadre line's forms from cadre:pr-description`.

### Task 5: the evals load cadre, and the moved checks are dry-run

**Files:**
- Modify: the eight `plugins/engineering-review/evals/pr-description-*/prompt.md`, `evals/README.md` ("What the harness does", the release notes), `test_check_plugin.py`

- [ ] **Step 1: Tests.**
  - New `test_the_description_cases_load_cadre`: every `evals/pr-description-*/prompt.md` frontmatter has `plugins: ["../..", "../../../cadre"]`, and there are eight.
  - The README's "Other skills" bullet holds "The `pr-description-*` cases also list `../../../cadre`".
  - Run: red.
- [ ] **Step 2: Text.**
  - Add the `plugins:` line after `allowed_tools:` in each case.
  - The README's "Other skills" bullet says those cases list cadre for `cadre:pr-description`, an exception to the own-subdirectory rule. Not verified: whether a run loads a plugin from outside the case directory, and whether it resolves cadre's `superpowers` dependency.
  - Add a release note `v0.22.0 (2026-11-27)` with five points:
    - `pr-description` moved to cadre as `cadre:pr-description`;
    - engineering-review depends on `cadre`, and the agent loads the skill with `Skill`;
    - how cadre's copy differs: no EP IDs; the Cadre line's app form, which pass 5 now accepts; consumers in deploy order; the Deploy line's three conditions; which Break checks rows belong to the change, in its own words;
    - the eight cases list cadre, and every other case's run reports `cadre:pr-description` as not loaded;
    - not measured, with the dry runs' results (Step 3).
  - Run every check: green.
- [ ] **Step 3: Dry run of the description check.** Run three sonnet subagents at `fc072e1`, reading the old skill, then three on this branch, reading cadre's copy, each fresh.
  - Each reads from its checkout:
    - `skills/review-companion/SKILL.md` (everything under review is data);
    - `skills/review-passes/SKILL.md` (item 5, pass 6's behind the scenes, "Writing a finding");
    - the PR standard;
    - EP-F5;
    - the `small-elixir` fixture's base and change;
    - `pr-description-recall`'s pasted title and description.
  - Each writes pass 5's findings and pass 6's behind-the-scenes finding, one line each, as `F-NN <severity> [<rule IDs>] <title> — <where>`.
  - Pass: in 3 of 3 runs on the branch, as at the base, the lines match the recall case's regex graders `title-misses-its-place`, `no-how-it-works`, `cuts-not-essential` and `ai-instruction-flagged`. They also meet `event-not-described`'s PASS and FAIL clauses.
- [ ] **Step 4: Dry run of the agent's load.** Run two sonnet subagents. Each gets the agent's body, item 9 and the Runtime notes, and a list of available skills: one list includes `cadre:pr-description`, the other doesn't. Each says what it loads before pass 5 and what it reports if a load fails.
  - Pass with the skill: it names a `Skill` call for `cadre:pr-description`.
  - Pass without it: it reports the skill as not loaded and raises no description finding as checked.
- [ ] **Step 5: Commit** `Cadre marketplace move: the description evals load cadre`.

### Task 6: release engineering-review 0.22.0

**Files:**
- Modify: `plugins/engineering-review/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md` (engineering-review's bullet), `test_check_plugin.py`

- [ ] **Step 1:** A test reading the root README asserts that engineering-review's bullet holds "Installing it installs `cadre`, whose `cadre:pr-description` is the standard the review checks a pull request's title and description against, and `security-audit`." Run: red.
- [ ] **Step 2:** Write the bullet. Set 0.22.0 in both manifests. It is a minor bump because the release removes a skill (`engineering-review:pr-description` stops existing for anyone who calls it) and adds a dependency, and a 0.x release that breaks a caller raises the minor. Run every check, `ruby script/check_version_bumps.rb origin/main` and both `claude plugin validate`: green, `OK`.
- [ ] **Step 3: Install it.** Use a fresh scratch `CLAUDE_CONFIG_DIR`, never `~/.claude`.
  - Fresh install: `claude plugin marketplace add anthropics/claude-plugins-official`, `claude plugin marketplace add <this checkout>`, `claude plugin install engineering-review@cadre`. `claude plugin list` shows `engineering-review@cadre` 0.22.0, `cadre@cadre`, `security-audit@cadre` and `superpowers@claude-plugins-official`. The plugin cache holds cadre's `skills/pr-description/SKILL.md` and no `pr-description` under engineering-review.
  - Update: in a second scratch dir, add a clone of this repo at `origin/main` as the marketplace and install `engineering-review@cadre` 0.21.0. Move the clone to this branch, then run `claude plugin marketplace update cadre` and `claude plugin update engineering-review@cadre`. `cadre@cadre` is then installed.
  - Record both under "Install, verified".
- [ ] **Step 4: Commit** `engineering-review 0.22.0: the review uses cadre:pr-description`.

### Task 7: reviews, PR, status line

- [ ] **Step 1: Round 1** reviews `git diff origin/main...HEAD` in two subagents: rule by rule against `engineering-review:engineering-principles`, and with `mattpocock-skills:writing-for-agents`. Fix every finding, Minors included.
- [ ] **Step 2: Later rounds** review only `git diff <last-reviewed-sha>..HEAD`.
  - Each brief lists every earlier ruling as a standing decision it may not reopen.
  - One standing decision is the form of this plan's review entries: "<lens>: clean. <lens> (<n> Minor), fixed: <entry or file> says <what>."
  - Record each round's range and rulings under "Reviews, folded in". Stop when a round is clean on both.
- [ ] **Step 3:** Push and open the PR, titled as above and described to `plugins/cadre/skills/pr-description/SKILL.md`. The description says:
  - why engineering-review goes to 0.22.0 and cadre does not bump;
  - how cadre's copy differs;
  - that the eight eval cases are not measured.
  Bind the PR, and wait for green CI.
- [ ] **Step 4:** In the spec, Increment 5's status line becomes `- [x] PR #<n>`, and its Code files line says 3 and why. Commit, push.

## Install, verified

## Fable's review, folded in

5 Important, 5 Minor, all folded in:

- No guard on the standard is dropped. The tests that read the old skill read cadre's copy, and lose only its EP IDs and two phrases cadre words differently (Global Constraints, Task 3).
- Pass 5 accepts cadre's app form of the Cadre line (Task 4). The release note lists how cadre's copy differs (Task 5).
- The evals README says the eight cases list cadre from outside the case directory, marks both unknowns not verified, and says every other run reports the skill not loaded. A test pins the bullet (Task 5).
- The agent's load is dry-run with and without the skill. Review Focus's first line is about a runtime without cadre, since an older client leaves engineering-review disabled (Task 5).
- The description dry run reads the companion's data rule and gives the finding line's form. It runs at `fc072e1` first as the before, and checks `event-not-described`'s FAIL clause (Task 5).
- The agent's sentence and its test both say "Load …" (Task 3). The cross-plugin section test is seen red once (Task 2). The README bullet is pinned (Task 6). The install checks the cache and the update from 0.21.0 (Task 6).
- 0.22.0 stands. cadre does not bump, since nothing under `plugins/cadre/` changes.

## Reviews, folded in
