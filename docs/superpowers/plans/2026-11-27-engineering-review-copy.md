# engineering-review copy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the cadre marketplace lists `engineering-review`, copied verbatim from colette-club, and `security-audit`, pinned; CI runs both suites and fails a pull request that changes a plugin without bumping its version. cadre 0.35.0 → 0.35.1.

**Architecture:** `plugins/engineering-review/` is extracted with `git archive` from colette-club's `main` at one named sha, so every tracked file and mode comes over and nothing else does. Only `plugin.json`'s `homepage` and `repository` change. A Ruby script, `script/check_version_bumps.rb`, compares each changed plugin's `plugin.json` version with the base's; `.github/workflows/checks.yml` runs it with both suites.

**Tech Stack:** Markdown skills, Minitest (cadre and the bump check), Python `unittest` (engineering-review), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, "`engineering-review` in the cadre marketplace" (the copy step) and Increment 4 only. PR title: `Cadre marketplace move (4/8): engineering-review in the cadre marketplace`.

**Skills to load:** `superpowers:writing-skills`, `mattpocock-skills:writing-for-agents` (wins where they disagree), `engineering-review:engineering-principles`, `mattpocock-skills:tdd`.

**Source:** `colette-club/colette-marketplace` `main` at `d8fbb87142919cbacd82ef09529ac1ca1bf59782` (fetched 2026-11-27): 547 files, 27 of them executable. colette-club is read, never edited.

**Code files:** 11 — the spec's 9, cadre's `plugin.json` (the release, counted as increments 1 to 3 count it) and `script/check_version_bumps.rb`. Under the 20 preferred; the spec's line is corrected in Task 6.

**Checks**, all green before every commit:

- `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`
- from Task 2: `python3 -m unittest discover -s plugins/engineering-review/scripts -p 'test_*.py'` (as colette-club's specs run it; 226 tests at the source sha) and `python3 plugins/engineering-review/scripts/check_plugin.py plugin plugins/engineering-review`, which prints `OK`
- `ruby test/check_version_bumps_test.rb`, from Task 3
- `claude plugin validate .` and `claude plugin validate plugins/engineering-review` pass

## Global Constraints

- colette-club's `plugins/engineering-review/` is frozen from this increment: the copy is byte-identical to the source except `plugin.json`'s `homepage` and `repository`, which become `https://github.com/djeusette/cadre_marketplace`. Its version stays `0.21.0`.
- `engineering-review` depends on `security-audit` only, by bare name, resolved in this marketplace.
- `security-audit` is listed with `{"source": "github", "repo": "cloudflare/security-audit-skill", "sha": "c1c8a8c1471069fb0e188eeaff69b8e8db6564a8"}`, the same full sha colette-club pins.
- The break-check spec is not copied.
- cadre depends on `superpowers@claude-plugins-official` alone. No EP ID and no "colette" in cadre's skill files; no "colette" in the README, outside the Cadre URL; `marketplace.json` names colette only as an author.
- No Skills rows or settings for `engineering-review` or `security-audit` in this repo: they come in increment 6, as `@cadre`.
- Every merge to `main` is a release. `plugins/cadre/test/plugin_test.rb` changes, so cadre bumps: 0.35.1, a patch, since no skill changes.
- Commit subjects follow the repo's `Cadre marketplace …` style.

## Review Focus

- A pull request that changes only a test or an eval inside `plugins/<name>/` still needs the bump: the check reads paths, not file kinds (Task 3, `test_a_change_to_any_file_of_a_plugin_needs_a_bump`).
- A new plugin, a removed plugin and a change outside `plugins/` pass the bump check; a lowered version fails it (Task 3).
- A PR where one plugin is bumped and another is not fails and names only the one not bumped (Task 3).
- A changed plugin whose `plugin.json` at the head has no version, one that is not a version number, or is not a JSON object fails with its name rather than crashing; a base with no version counts as lower (Task 3).
- An unknown base or a shallow checkout exits 2 with git's message, never `OK`; a file moved from one plugin to another needs both bumped (Task 3).
- `engineering-review@cadre` installs from this checkout with `security-audit` beside it, in a throwaway config dir (Task 5).
- The copy is verbatim: `git ls-tree -r` of the copy against the source sha differs on the `plugin.json` line alone, so every other file has the same blob and mode, hidden fixture files included (Task 2, Step 4).

---

### Task 1: cadre's tests let the marketplace hold three plugins

**Files:**
- Create: this plan
- Modify: `plugins/cadre/test/plugin_test.rb` (`test_marketplace_lists_cadre_last_at_the_plugin_version`, `test_readme_sums_cadre_up_and_links_its_skill`, `test_agents_md_names_the_checks_the_release_and_which_skill_wins`), `AGENTS.md` ("Release")

**Interfaces:**
- Produces: `test_marketplace_lists_cadre_at_the_plugin_version`, which Task 5 bumps; the cadre README bullet read up to the next bullet or heading.

- [ ] **Step 1: Change the tests**
  - Rename `test_marketplace_lists_cadre_last_at_the_plugin_version` to `test_marketplace_lists_cadre_at_the_plugin_version` and drop its `last` assertion. A one-line comment says why it pins no place, as the brief asks: the marketplace lists other plugins too.
  - In `test_agents_md_names_the_checks_the_release_and_which_skill_wins`, both names go to the new one (the string and the `public_instance_methods` check).
  - In `test_readme_sums_cadre_up_and_links_its_skill`, the bullet ends at the next bullet or heading: `(?=^- \*\*|^#|\z)`.
- [ ] **Step 2: Run the cadre suite.** Expected: one failure, the AGENTS.md string.
- [ ] **Step 3: "Release" in `AGENTS.md` names the new test.**
- [ ] **Step 4: Run the cadre suite.** Expected: green.
- [ ] **Step 5: Commit** `Cadre marketplace: cadre's tests let the marketplace list other plugins`, with this plan.

### Task 2: the copy

**Files:**
- Create: `plugins/engineering-review/**` (every file at the source sha)
- Modify: `plugins/engineering-review/.claude-plugin/plugin.json` (`homepage`, `repository`), `.claude-plugin/marketplace.json`, `README.md` ("Plugins")

**Interfaces:**
- Consumes: Task 1's tests, which no longer pin cadre last or read past its bullet.
- Produces: the plugin at `./plugins/engineering-review`, version `0.21.0`.

- [ ] **Step 1: Extract.** `git -C ~/Code/colette-marketplace fetch origin`, check `origin/main` is still the source sha (else use the new head and name it), then `git -C ~/Code/colette-marketplace archive <sha> plugins/engineering-review | tar -x -C .`.
- [ ] **Step 2: Run the Python tests and `check_plugin.py`.** Expected red: `test_the_plugin_depends_on_the_pinned_security_audit_skill` (no `security-audit` entry), `test_real_plugin_passes` (no `engineering-review` entry), the README tests (`security-audit`, "runs the repository's tests and checks") and `check_plugin`'s manifest check (no `engineering-review` entry).
- [ ] **Step 3: Make them green.**
  - `plugin.json`: `homepage` and `repository` → `https://github.com/djeusette/cadre_marketplace`.
  - `marketplace.json`: after cadre, colette-club's `engineering-review` and `security-audit` entries as they are there, with `"source": "./plugins/engineering-review"`.
  - `README.md` "Plugins", after the cadre bullet: an `engineering-review` bullet that names the principles, `review-companion`, `break-check`, that the review loads the skills the repository's `AGENTS.md` Skills table lists, runs the repository's tests and checks, runs Cloudflare's `security-audit` skill as its security layer, and that installing it installs `security-audit`; a `security-audit` bullet linking Cloudflare's repo and saying it is pinned to one commit.
- [ ] **Step 4: Check the copy is verbatim.** After `git add plugins/engineering-review`, `diff <(git -C ~/Code/colette-marketplace ls-tree -r <sha> plugins/engineering-review) <(git ls-tree -r "$(git write-tree)" plugins/engineering-review)` differs on the `plugin.json` line alone, so every other file has the same blob and mode. `diff <(git -C ~/Code/colette-marketplace show <sha>:plugins/engineering-review/.claude-plugin/plugin.json) plugins/engineering-review/.claude-plugin/plugin.json` shows only `homepage` and `repository`.
- [ ] **Step 5: Run every check, both `claude plugin validate` included.** Expected: green.
- [ ] **Step 6: Commit** `Cadre marketplace: engineering-review copied from colette-club at <sha>`, the body naming the full source sha and the two changed keys.

### Task 3: the version-bump check

**Files:**
- Create: `script/check_version_bumps.rb`, `test/check_version_bumps_test.rb`

**Interfaces:**
- Produces: `ruby script/check_version_bumps.rb <base>`. The plugins are the `plugins/<name>/` that `git diff --name-only --no-renames -z <base>...HEAD -- plugins/` touches. Each one whose `.claude-plugin/plugin.json` exists at `HEAD` must have a version number (`Gem::Version`) there, higher than the base's when the base has one. A plugin gone at `HEAD` passes. Files are read as UTF-8. Output, exactly:
  - `OK`, exit 0;
  - per failing plugin, exit 1: `plugins/<name> changed but its version <v> is not above <base v>`, `plugins/<name> has no version in .claude-plugin/plugin.json`, `plugins/<name> has version "<v>" in .claude-plugin/plugin.json, which is not a version number`, or `plugins/<name> has a .claude-plugin/plugin.json that is not a JSON object`;
  - usage with no argument, or git's message when git fails (an unknown base, no merge base), exit 2.

The seam is the script's command line, run in a throwaway git repo (global and system config off, a fixed author). No test calls the script's functions directly.

- [ ] **Step 1: One red-green per case**, in this order, each test asserting the exit status and the exact output line, each seen red on its own assertion before the code that turns it green:
  - `test_a_change_without_a_bump_fails_and_names_the_plugin`;
  - `test_a_change_with_a_bump_passes`;
  - `test_a_lowered_version_fails`;
  - `test_a_change_to_any_file_of_a_plugin_needs_a_bump` (`plugins/demo/test/x_test.rb` alone);
  - `test_only_the_plugin_not_bumped_is_named`;
  - `test_a_file_moved_between_plugins_needs_both_bumped`;
  - `test_a_new_plugin_passes`, `test_a_new_plugin_without_a_version_fails`;
  - `test_a_plugin_whose_base_has_no_version_passes_once_it_has_one`;
  - `test_a_version_that_is_not_a_version_number_fails_and_names_the_plugin` (`v0.36.0`);
  - `test_a_plugin_json_that_is_not_json_fails_and_names_the_plugin`, `test_a_plugin_json_that_is_not_an_object_fails_and_names_the_plugin`;
  - `test_a_plugin_whose_base_plugin_json_is_not_json_passes_once_it_has_a_version`;
  - `test_a_plugin_with_several_changed_files_is_named_once`;
  - `test_a_removed_plugin_passes`, `test_a_change_outside_plugins_passes`;
  - `test_an_unknown_base_fails`, `test_no_base_prints_the_usage` (exit 2).
- [ ] **Step 2:** the script's header comment gives the usage and the rule.
- [ ] **Step 3: Run every check.** Expected: green.
- [ ] **Step 4: Commit** `Cadre marketplace: a check that each changed plugin bumps its version`.

### Task 4: CI and the docs that name the checks

**Files:**
- Create: `.github/workflows/checks.yml`
- Modify: `AGENTS.md` ("Checks", "Release"), `README.md` ("Development"), `plugins/cadre/test/plugin_test.rb` (`test_agents_md_names_the_checks_the_release_and_which_skill_wins`)

- [ ] **Step 1: Change the tests.** AGENTS.md must hold the two engineering-review commands of **Checks**, `ruby test/check_version_bumps_test.rb` and the bump rule's words "bumps that plugin's version"; the existing strings stay. README must hold `To run the checks, follow "Checks" in [AGENTS.md](AGENTS.md).`
- [ ] **Step 2: Run the cadre suite.** Expected: that test fails on the first new string.
- [ ] **Step 3: Write the docs.**
  - "Checks" lists the three suites and `check_plugin.py`, and keeps the `LANG` gotcha and the test-first rule, which now holds for `test_check_plugin.py` too.
  - "Release": every merge to `main` is a release, so a pull request that changes `plugins/<name>/` bumps that plugin's version. cadre's version sits in `plugin.json`, `marketplace.json` and `test_marketplace_lists_cadre_at_the_plugin_version`; engineering-review's in `plugin.json` and `marketplace.json`.
  - README "Development" holds the pinned sentence instead of the cadre command; its Release line stays.
- [ ] **Step 4: Write `.github/workflows/checks.yml`**, `name: Checks`, on `push` to `main` and `pull_request`, `permissions: contents: read`, three jobs on `ubuntu-latest` with `actions/checkout@v4`:
  - `ruby`: `ruby/setup-ruby@v1` 3.4, `LANG: C.UTF-8` (ubuntu's installed locale); the cadre suite and `ruby test/check_version_bumps_test.rb`.
  - `engineering-review`: `actions/setup-python@v5` 3.13; the unittest command and `check_plugin.py`.
  - `version-bumps`: on `pull_request` only; checkout with `fetch-depth: 0`; Ruby 3.4; `ruby script/check_version_bumps.rb "$BASE"` with `BASE: origin/${{ github.base_ref }}` in `env`, never in the command.
- [ ] **Step 5: Run every check.** Expected: green. The workflow itself is checked on the PR.
- [ ] **Step 6: Commit** `Cadre marketplace: CI runs both suites and the version-bump check`.

### Task 5: release cadre 0.35.1

**Files:**
- Modify: `plugins/cadre/test/plugin_test.rb`, `plugins/cadre/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

- [ ] **Step 1:** `test_marketplace_lists_cadre_at_the_plugin_version` expects `0.35.1`; run the cadre suite, see it red.
- [ ] **Step 2:** 0.35.1 in both manifests; run every check and `ruby script/check_version_bumps.rb origin/main`. Expected: green, `OK`.
- [ ] **Step 3: Install it.** With `CLAUDE_CONFIG_DIR` set to a fresh scratch dir (never `~/.claude`): `claude plugin marketplace add <this checkout>`, `claude plugin install engineering-review@cadre`, then `claude plugin list` shows `engineering-review@cadre` and `security-audit@cadre`. If it can't run here, the PR says it was not verified.
- [ ] **Step 4: Commit** `Cadre 0.35.1: the marketplace lists engineering-review and security-audit`.

### Task 6: reviews, PR, status line

- [ ] **Step 1: Round 1** reviews `git diff origin/main...HEAD` rule by rule against `engineering-review:engineering-principles`, and with `mattpocock-skills:writing-for-agents`, in two subagents. Findings on the files under `plugins/engineering-review/` are out of scope, except whether they are verbatim. Fix every finding, Minors included.
- [ ] **Step 2: Later rounds** review only `git diff <last-reviewed-sha>..HEAD`, each brief listing every earlier ruling as a standing decision it may not reopen. Each round's range and rulings go in "Reviews, folded in" below. Stop when a round is clean on both.
- [ ] **Step 3:** push, open the PR titled as above and described to `plugins/cadre/skills/pr-description/SKILL.md`, saying why cadre bumps to 0.35.1 and engineering-review stays 0.21.0.
- [ ] **Step 4:** Increment 4's status line in the spec becomes `- [x] PR #<n>`, and its Code files line says 11 with the two added; commit, push.

## Install, verified

2026-11-27, `CLAUDE_CONFIG_DIR` set to a scratch dir: `claude plugin marketplace add <this checkout>` then `claude plugin install engineering-review@cadre` installed `engineering-review@cadre` 0.21.0 "(+ 1 dependency: security-audit)"; `claude plugin list` shows both enabled, `security-audit` at `c1c8a8c14710`.

## Fable's review, folded in

4 Important, 6 Minor, all folded in:

- The bump check exits 2 on any git failure, diffs with `--no-renames -z`, reads UTF-8, requires a readable version at `HEAD` for every changed plugin (a versionless base counts as lower), and pins its two failure lines; one red-green per case.
- Task 5 installs `engineering-review@cadre` in a throwaway config dir, so the bare-name dependency is proven.
- The code-file count is 11, stated here and corrected in the spec.
- Task 2 compares the staged tree (`git write-tree`) and derives the count from the source; `test_real_plugin_passes` is in the red list.
- CI runs the bump tests in the `ruby` job on push too, with `LANG: C.UTF-8`.
- The plan is committed with Task 1; the README Development pointer is pinned; AGENTS.md drops what the workflow and `check_plugin.py` already say.
- Kept: the why-comment in the renamed test, which the brief asks for and which states a reason, not history.
- For David, not this PR: `main` is unprotected, so a red check doesn't block a merge, and checks don't re-run when `main` moves (two PRs can both bump to the same version). Repo-level tests in `plugins/cadre/test` force a cadre release for README or AGENTS wording changes.

## Reviews, folded in

### Round 1: `origin/main...edbb863`, full branch

engineering-principles (2 Minor) and writing-for-agents (2 Important, 4 Minor). The copy is verbatim. Fixed:

- A `plugin.json` at `HEAD` that is not a JSON object (a trailing comma, a top-level `[]`) is named, exit 1, instead of a backtrace; at the base it counts as no version. Tests for both shapes at `HEAD`, and for a plugin with several changed files named once; the no-op `.sort` is gone.
- "Not a version number" is the one term, in the test name and the plan; the script's header says a version number is needed at `HEAD` even when the base has none.
- README's opening describes the marketplace, not only cadre's plugins.
- The workflow's job and step names say what each runs.
- The plan's "Nothing is tested inside it" says which thing.

Declined, as a standing ruling: an `engineering-review@cadre` install line in README "Use it". No team machine should hold `engineering-review@cadre` beside `@colette-club` before increment 6's switch (the spec's anti-goal), and the bullet already says what the plugin is.

### Round 2: `edbb863..5dea840`

engineering-principles (1 Important, 3 Minor) and writing-for-agents (2 Important, 5 Minor), all fixed but one:

- A base `plugin.json` that is not JSON is tested (red with `base_version`'s rescue removed); Task 3's case list and Round 1's line name every test.
- The three round 1 tests are indented like their neighbours (a `<<~` heredoc had stripped them).
- `manifest`'s comment says it raises `NotAnObject`.
- README's opening names `security-audit`; the workflow's job and step names say what runs.

Declined, as a standing ruling: rewording round 1's commit message. Commits are history; the plan's Round 1 line carries the accurate wording.
