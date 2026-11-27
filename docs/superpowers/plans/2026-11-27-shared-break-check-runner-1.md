# Break check (1/5): the shared runner in engineering-review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ruby <engineering-review>/scripts/break_check.rb` works in any repository with a `.break-check.json`, as cadre's runner works in cadre. The skill and `contract.md` describe it. engineering-review 0.22.0 → 0.23.0.

**Architecture:** cadre's runner (`~/Code/cadre/script/`, merged as `354ee07e`, unchanged since) is copied verbatim, then its CLI moves into `break_check/cli.rb` with no change of behaviour. Those two commits are the port's base: every line changed after them is new, and `--uncovered <port base>` lists exactly the lines to break. On top, `break_check/profile.rb` stops holding cadre's two profiles and reads them from `.break-check.json`, and `break_check.rb` becomes an entry point that refuses Ruby older than 3.2 before it loads any file that needs 3.2.

**Tech Stack:** Ruby 3.2+ standard library, Minitest; Python `unittest` (engineering-review's checks); GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-27-shared-break-check-runner-design.md`, "The runner", "`.break-check.json`", "The ledger", "The skill" and Increment 1. PR title: `Break check (1/5): the shared runner in engineering-review`.

**Skills to load:** `engineering-review:engineering-principles`, `mattpocock-skills:tdd`, `security-audit:security-audit` (the runner runs commands from a file), `mattpocock-skills:writing-for-agents` (AGENTS.md in Tasks 1–2, the skill in Task 4, where it wins over `superpowers:writing-skills`), and `superpowers:writing-skills` for Task 4.

**Code files:** 10: `scripts/break_check.rb`, the seven files under `scripts/break_check/` (cadre's six and `cli.rb`), `.claude-plugin/marketplace.json`, `.github/workflows/checks.yml`; plus `plugin.json`, `.break-check.json` and `.gitignore`. The spec's "about 10" counted six library files; the seventh, `cli.rb`, exists so the entry point parses on old Ruby (Task 3).

**Checks**, all green before every commit (AGENTS.md's, plus the runner's tests from Task 1 on):

- `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`
- `python3 -m unittest discover -s plugins/engineering-review/scripts -p 'test_*.py'`
- `python3 plugins/engineering-review/scripts/check_plugin.py plugin plugins/engineering-review` prints `OK`
- `ruby test/check_version_bumps_test.rb`
- `ruby plugins/engineering-review/scripts/test_break_check/all.rb`
- before the PR: `ruby script/check_version_bumps.rb origin/main` prints `OK`; `~/.local/bin/claude plugin validate plugins/engineering-review` passes.

## Global Constraints

- Ruby 3.2 or later runs the runner; older Ruby gets exit 2 naming 3.2. Standard library only.
- The runner never writes to its own directory: `.breaks/` and everything in it stay under the directory it runs in.
- No behaviour of cadre's runner changes beyond the profile file and the version guard. The five known gaps stay for increment 3.
- The ported tests keep every assertion. Only their harness changes: how a profile is built (from data, not `Profiles.exunit`/`Profiles.minitest`), `CLI.run` losing its `profiles:` argument, and the two exunit command tests moving to `profile_test.rb`. They count as the port's proof (David's call); every branch Tasks 2–3 add or change gets a break through the worktree's runner.
- Nothing under `plugins/cadre/` changes, so cadre does not bump.
- `test_check_plugin.py` pins the skill's wording: change the test first, watch it go red, then the text. No skill or contract text writes `ruby script/break_check.rb` (`test_no_test_command_is_written_down`).
- Commit subjects: `Break check: …`, and the release commit `engineering-review 0.23.0: …`.
- The branch is merged with `main`, never rebased: the port base's SHA must stay reachable.

## Review Focus

- Run from a subdirectory, or in a repo with no `.break-check.json`: every command, `--table` and `--stale` included, exits 2 naming `.break-check.json` and the directory, so no empty table or `0 stale` reads as an all-clear (Task 2, `test_a_missing_settings_file_refuses`, `test_table_and_stale_refuse_without_settings`).
- A mistyped `watched` path (`libs`): exit 2 naming it, never `0 changed lines have no fresh proof` (Task 2, slice 11).
- A hand-written pattern that isn't a valid Ruby regexp, or a `failing_test` with no group: exit 2 naming the profile and the key, before any test runs (Task 2).
- A command without `{files}`, or with it twice or first: refused, since every break would run the whole suite, or nothing, or through the shell (Task 2).
- A settings file with non-ASCII text read under an ASCII locale: read as UTF-8, like every file the runner reads (Task 2, `test_settings_are_read_as_utf_8_whatever_the_locale`).
- macOS's `/usr/bin/ruby` (2.6) running the runner: exit 2 naming 3.2, no `SyntaxError` (Task 3's tests, its manual check, and CI's `old-ruby` job on 2.6 and 3.1).

---

### Task 1: the port's base

**Files:**
- Create: `plugins/engineering-review/scripts/break_check.rb`, `scripts/break_check/{breaks,ledger,profile,run,uncovered,workspace}.rb`, `scripts/test_break_check/*.rb` (cadre's `script/test/` as it is), then `scripts/break_check/cli.rb`
- Modify: `AGENTS.md` (Checks), `.github/workflows/checks.yml`, `.gitignore`

- [ ] **Step 1:** `git -C ~/Code/cadre archive 354ee07e script/break_check.rb script/break_check script/test | tar -x -C <scratch>`, then move `script/break_check.rb` and `script/break_check/` under `plugins/engineering-review/scripts/` and `script/test/` to `plugins/engineering-review/scripts/test_break_check/`. Prove it verbatim: `diff -r` against the archive prints nothing.
- [ ] **Step 2:** Run `ruby plugins/engineering-review/scripts/test_break_check/all.rb`: green. Add it to AGENTS.md's Checks. Add `.breaks/` to `.gitignore`. Add to `checks.yml` a job `break-check` ("the break-check runner's tests"), matrix `ruby-version: ["3.2", "3.4"]`, `LANG: C.UTF-8`, running that command. Run every check. **Commit** `Break check: copy cadre's runner and its tests as they are`.
- [ ] **Step 3:** Move `module BreakCheck::CLI` and its `require`s from `break_check.rb` into `break_check/cli.rb` unchanged. `break_check.rb` keeps the shebang, `require_relative "break_check/cli"` and the `$PROGRAM_NAME == __FILE__` block; its comment's "Every runner file is required here" moves to `cli.rb` with the `require`s, and "See script/README.md" becomes "See skills/break-check/contract.md". Tests: green, unchanged. **Commit** `Break check: the CLI in its own file`. This commit's SHA is the **port base**; write it into Task 5's commands, and never rebase past it.

### Task 2: profiles come from `.break-check.json`

**Files:**
- Modify: `scripts/break_check/profile.rb`, `scripts/break_check/cli.rb`, `scripts/test_break_check/{test_helper,fake_profile,cli_test,run_test,uncovered_test}.rb`
- Create: `scripts/test_break_check/profile_test.rb`, `.break-check.json`

**Interfaces:**
- Produces: `BreakCheck::Profiles.load(root, name:, partition:) -> Profile`, which reads `<root>/.break-check.json` and picks the profile; `BreakCheck::Profiles.build(name, fields, partition:) -> Profile`, which checks one profile's `fields` (a Hash as parsed from JSON) and builds it. Both raise `BreakCheck::Usage`, whose message starts `.break-check.json: ` and names the profile and key. `Profile` keeps its fields, so `Run` and `Uncovered` don't change: `command` is still a lambda `files -> [env, *argv]`.
- Test data in `test_helper.rb`: `EXUNIT` and `MINITEST`, cadre's two profiles as JSON-shaped hashes (the spec's exunit block; minitest with `"command": ["ruby", "-e", "ARGV.each { require File.expand_path(_1) }", "{files}"]`, `"failing_test": "^\\s+\\d+\\) (?:Failure|Error):\\n(\\S+#test_\\w+)"`, `"compile_error": "SyntaxError"`, `"timeout": 120`, cadre's `watched` and `noise`), and `RepoHelper.settings(profiles, default: nil) -> String` (the JSON; a module function, since `FILES` is built in the class body). `FakeProfile.fields(timeout: 10) -> Hash` is `EXUNIT.except("env").merge("command" => [RbConfig.ruby, FAKE, "{files}"], "timeout" => timeout)`, and `FakeProfile.call(timeout:)` is `Profiles.build("fake", fields(timeout:), partition: nil)`. `CliTest::FILES` gains `".break-check.json"` holding `exunit` (the default) and `fake`; `cli(argv)` passes `--profile fake`. `UncoveredTest#with_git_repo` commits a `.break-check.json` holding `exunit` alone. `RunTest` needs none. The TERM test writes its own settings file whose `fake` has `timeout: 60`, and its `-e` string calls `BreakCheck::CLI.run(['breaks.json', '--profile', 'fake'], out: $stdout)`.

The rules, each its own red → green slice in `profile_test.rb`, in this order:

1. `test_a_missing_settings_file_refuses`: no file → `Usage` naming `.break-check.json` and the root.
2. Not JSON → names the parser's first line. Not an object, or `profiles` not a non-empty object → `profiles must name at least one profile`. A top-level key other than `profiles` and `default` → `unknown key <k>`.
3. Two or more profiles and no `default` → `default is required when there is more than one profile`. A `default` that names no profile → `default names no profile: <d>`.
4. `name:` given → that profile, else `default`, else the only one. An unknown name → `unknown profile <name>` (the ported CLI test's words).
5. `build`: a missing required key (`command failing_test compile_error timeout watched noise`) → `profile <p>: missing <k>`; a key outside those and `env infrastructure refusal doc_open doc_close` → `profile <p>: unknown key <k>`.
6. Each pattern key is a string that compiles as a Ruby regexp (flags go inline, `(?m)`) → else `profile <p>: <k> is not a valid pattern: <error>`. `failing_test` holds at least one group, counted as `Regexp.new(source + "|").match("").captures.size` so `(?:…)` doesn't count → else `failing_test needs a group that captures the test's name`. `doc_open` and `doc_close` come together or not at all.
7. `command` is a list of strings holding `{files}` exactly once, as a whole element and not the first (a one-string `Process.spawn` goes through the shell); `env` maps strings to strings; `timeout` is a positive number; `watched` is a non-empty list of strings. Each → `profile <p>: <k> must be …`.
8. `command.call(files)`: the `{files}` element becomes the files; `{partition}` in any command or env string becomes N. The ported `test_the_ex_unit_command_runs_one_partition_in_a_fixed_order` asserts `[{"MIX_TEST_PARTITION" => "3"}, "mise", "exec", "--", "mix", "test", "--seed", "0", "test/a_test.exs"]` for `build("exunit", EXUNIT, partition: 3)`.
9. A profile that names `{partition}` without one: `command.call` raises `Usage` with `--partition N is required to run tests with <p>` (lazy, as today: `--uncovered` and an empty replay need none). One that names none, given a partition: `build` raises `profile <p> takes no --partition`.
10. `test_settings_are_read_as_utf_8_whatever_the_locale`: a profile name with `→`, read under `with_ascii_locale`, loads (`BreakCheck.read`).
11. `load` (not `build`, which the MINITEST uncovered test calls where its paths don't exist) refuses a `watched` path absent under the root: `profile <p>: watched path <w> does not exist`.
12. `dispatch` loads the profile before every command, `--table` and plain `--stale` included: `test_table_and_stale_refuse_without_settings` (CLI, exit 2).

- [ ] **Step 1:** Slices 1–10, each: write the test, run `ruby plugins/engineering-review/scripts/test_break_check/profile_test.rb -n <test>`, see it fail for the right reason, write the code, see it pass.
- [ ] **Step 2:** Migrate the harness as Interfaces says; `CLI.run(argv, out:)` and `CLI.profile(options) = Profiles.load(Dir.pwd, name: options[:profile], partition: options[:partition])`; `parse` starts from `{}` instead of `{profile: "exunit"}`; `PROFILES` goes. Drop `Profiles.exunit`/`Profiles.minitest`. Every ported assertion passes as it was.
- [ ] **Step 3:** Commit this repo's `.break-check.json`: one profile, `minitest`, `MINITEST`'s values with `watched` `["plugins/engineering-review/scripts/break_check.rb", "plugins/engineering-review/scripts/break_check"]`. AGENTS.md's Checks gains one line: a change to the runner's code is broken with this checkout's runner, `ruby plugins/engineering-review/scripts/break_check.rb .breaks/<task>.json`. Fix the spec's "`{partition}` to `--partition N`" to "`{partition}` to the N of `--partition N`". Run every check. **Commit** `Break check: profiles come from .break-check.json`.
- [ ] **Step 4:** Break check (Task 5's "After a task" recipe, base = port base).

### Task 3: the entry point refuses Ruby older than 3.2

**Files:**
- Modify: `scripts/break_check.rb`, `scripts/break_check/cli.rb` (`BANNER`)
- Test: `scripts/test_break_check/cli_test.rb`

- [ ] **Step 1:** `test_ruby_older_than_3_2_refuses`: spawn `RbConfig.ruby -W0 -e 'Object.send(:remove_const, :RUBY_VERSION); RUBY_VERSION = "3.1.4"; load <break_check.rb>'`; assert exit 2 and stdout `break_check.rb needs Ruby 3.2 or later; this is Ruby 3.1.4`. `test_ruby_3_2_runs`: the same with `"3.2.0"` and `; puts :loaded` after the `load` exits 0 and prints `loaded` (it catches `<` → `<=`). Red, then green.
- [ ] **Step 2:** `break_check.rb` compares `RUBY_VERSION` with `"3.2"` (`Gem::Version`) before `require_relative "break_check/cli"`, prints that line on stdout and exits 2. The file uses no syntax newer than Ruby 2.0, so old Ruby reaches the check. Green.
- [ ] **Step 3:** `BANNER` names `break_check.rb`, not `script/break_check.rb`, shows `--profile NAME` and `--partition N` as optional on the commands that run tests, and ends `Run from the repository root; profiles come from its .break-check.json.`
- [ ] **Step 4:** `/usr/bin/ruby plugins/engineering-review/scripts/break_check.rb --help` exits 2 with the line. Add to `checks.yml` a job `old-ruby`, matrix `["2.6", "3.1"]` (3.1 parses everything but `Data`; 2.6 catches newer syntax), asserting the same exit and line. Run every check. **Commit** `Break check: the runner refuses Ruby older than 3.2`.
- [ ] **Step 5:** `--stale --replay` first (Task 3 edits `cli.rb`, so Task 2's proofs there go stale), then the break check (base = port base).

### Task 4: the skill and `contract.md`

**Files:**
- Modify: `skills/break-check/SKILL.md`, `skills/break-check/contract.md`, `scripts/test_check_plugin.py` (`test_break_check_skill_gives_the_recipes_the_ledger_and_the_contract`)

- [ ] **Step 1:** Change the test first, then see it red. Out: `A repository with no runner gets one before its first break`, `354ee07e`, `script/break_check/profile.rb`. In (SKILL.md): `## Before you start`, `ruby --version`, `3.2`, `../../scripts/break_check.rb`, `.break-check.json`, `a committed runner of the repository's own wins`; (contract.md): `## .break-check.json` in place of `## The profile` (its Contents anchor is `#break-checkjson`), `{files}`, `{partition}`, `"default"`, `scripts/break_check/`, `scripts/test_break_check/`, `exit 2`. `Look for a committed runner`, `## Known gaps` and its two hand-edit lines stay.
- [ ] **Step 2:** SKILL.md, as the spec's "The skill" says: description ends `…before a PR, or to write a repository's .break-check.json.`; "Before you start" checks `ruby --version` is 3.2 or later and the repo root holds `.break-check.json` or its own runner; "The runner": `<runner>` is the repository's own committed runner while it has one (cadre until increment 2), else `ruby <this skill's base directory>/../../scripts/break_check.rb`, run from the repository root; a repository with neither gets `.break-check.json` before its first break, its patterns written from its tests' real output (a failing test, a compile error), and one break of an existing branch as its check. `<runner> --help` and `--profile`/`--partition` replace "whatever the repository's tests need". The intro's "Each repository commits a runner" becomes the plugin's runner reading the repository's `.break-check.json`; Exit codes' **2** gains a missing or invalid `.break-check.json`, an unknown profile and Ruby older than 3.2. Paths under `scripts/` are code spans, never links (`check_plugin.py` refuses links that leave the skill's folder). The description stays within 30 words (`test_check_plugin.py`'s limit).
- [ ] **Step 3:** contract.md becomes the shared runner's documentation: "what a break-check runner does" written as what this runner does; "The command line" with `--profile NAME` and `--partition N`; Internals unchanged; `## .break-check.json` with every field, its type, which are optional, `{files}`/`{partition}`, `default`, inline flags, and the refusals, its example this repo's `minitest` profile (the spec's exunit block trips `test_no_test_command_is_written_down` on `mix test`); "Its tests" names `scripts/test_break_check/`; Known gaps unchanged ("fixed in increment 3" not promised in text); "Reference implementation" points at this plugin's `scripts/break_check.rb` and `scripts/break_check/`, ported from cadre's runner (djeusette/cadre#159).
- [ ] **Step 4:** Widen the `break-checks-ledger` eval's `never-runs-the-runner` grader from `script/break_check\.rb` to `scripts?/break_check\.rb`, its test (`test_break_checks_ledger_graders_read_the_cards_not_the_answers`) first with a `ruby ~/.claude/plugins/cache/cadre/engineering-review/0.23.0/scripts/break_check.rb --table` case.
- [ ] **Step 5:** Bump engineering-review to 0.23.0 in `plugin.json` and `marketplace.json`. Run every check. **Commit** `engineering-review 0.23.0: the shared break-check runner`.

### Task 5: break checks, reviews and the PR

Recipes, run from the worktree root (one profile, so `--profile` is left out). The port base is `8e6fce1`:

- After a task: `ruby plugins/engineering-review/scripts/break_check.rb --uncovered <port base>`; one break per branch on the listed lines into `.breaks/task-<n>.json` with the test files that cover it; run the file; a `NOT CAUGHT` gets a test.
- Before the PR: `--stale --replay`, `--uncovered <port base>` (every listed line holds no branch), `--table`.

- [ ] **Step 1:** Before-the-PR recipe; keep the table for the description. `--uncovered origin/main` would list every ported line: the description says why the base is the port base.
- [ ] **Step 2:** `ruby script/check_version_bumps.rb origin/main` prints `OK`; `~/.local/bin/claude plugin validate plugins/engineering-review` passes.
- [ ] **Step 3:** Review rounds, two lenses (engineering-principles rule by rule; writing-for-agents). Round 1 covers the branch; later rounds cover `git diff <last reviewed sha>..HEAD` with earlier rulings standing. Record each round as "<lens> (<n> Minor), fixed: <file> says <what>." Stop at a round clean on both.
- [ ] **Step 4:** Push, open the PR with `cadre:pr-description` (no Cadre line: not tracked), set Increment 1's status line to `- [x] PR #<n>`, push. Done when CI is green.

## Plan review

Fable (0 Critical, 6 Important, 10 Minor), folded in: settings load for every command; a missing `watched` path refuses; the TERM test and `UncoveredTest` get their own settings; contract.md's example is the minitest profile; `--stale --replay` before Task 3's breaks and no rebase past the port base; `{files}` once, whole, not first; the group count; a `3.2.0` runs test and `old-ruby` on 2.6 and 3.1; Task 4's intro, exit 2, code spans, anchor and 30 words; the eval grader widened; the spec's `{partition}` sentence.
