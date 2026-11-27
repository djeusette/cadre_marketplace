# Break check (3/5): the five known gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** engineering-review's break-check runner closes the five gaps `contract.md` lists: `--table BASE`, a freed name after a replay that doesn't compile, a profile per proof, fenced backticks, and branches narrowed by deletion. engineering-review 0.23.0 → 0.24.0.

**Architecture:** One task per gap, each red first, with its docs. A new `break_check/diff.rb` reads `git diff BASE` once into the lines a change adds and the places it deletes lines; `Uncovered` (gap 5) and `--table BASE` (gap 1) both read it, so the rule "a proof belongs to a change" lives in one place. A proof's span (the lines its `from` covers) moves from `Uncovered` to `Ledger#span`, read by both.

**Tech Stack:** Ruby 3.2+ standard library, Minitest; Python `unittest` (engineering-review's checks).

**Spec:** `docs/superpowers/specs/2026-11-27-shared-break-check-runner-design.md`, "The ledger", "The five gaps (increment 3)", Constraints, Anti-goals, Increment 3. PR title: `Break check (3/5): the five known gaps`.

**Skills to load:** `engineering-review:engineering-principles`, `engineering-review:break-check` (read this checkout's `plugins/engineering-review/skills/break-check/SKILL.md`: the installed copy may be older), `mattpocock-skills:tdd`, `security-audit:security-audit` (the runner runs commands from a file and passes BASE to git), `mattpocock-skills:writing-for-agents` and `superpowers:writing-skills` for SKILL.md and contract.md (writing-for-agents wins where they disagree).

**Code files:** 8: `scripts/break_check/{cli,diff,ledger,profile,run,uncovered}.rb`, `plugin.json`, `marketplace.json`.

**Plan review:** Fable, 2026-11-27: 1 Critical (a deletion merged with a changed noise line), 7 Important, 8 Minor, folded into Decisions and Tasks 2–6. The spec's "about 6" did not count `diff.rb`, which exists so gaps 1 and 5 share one diff reader.

**Checks**, all green before every commit (AGENTS.md's):

- `LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`
- `python3 -m unittest discover -s plugins/engineering-review/scripts -p 'test_*.py'`
- `python3 plugins/engineering-review/scripts/check_plugin.py plugin plugins/engineering-review` prints `OK`
- `ruby test/check_version_bumps_test.rb`
- `ruby plugins/engineering-review/scripts/test_break_check/all.rb`
- before the PR: `ruby script/check_version_bumps.rb origin/main` prints `OK`; `~/.local/bin/claude plugin validate plugins/engineering-review` passes.

**Breaks**, after each task's tests are green, as the checkout's SKILL.md says, with `R=plugins/engineering-review/scripts/break_check.rb`: `ruby $R --uncovered <task base>`, one break per branch the task adds or changes in `.breaks/task-<n>.json` (tests listed as `plugins/engineering-review/scripts/test_break_check/<file>_test.rb`), `ruby $R .breaks/task-<n>.json` until it exits 0. The running runner has every file loaded before a break, so breaking its own code is safe. The PR base is `d1c860c`.

## Global Constraints

- `break_check.rb` itself parses on Ruby 2.6 and 3.1 and exits 2 naming 3.2 (CI's `old-ruby` job). New syntax goes in the library files only.
- A ledger line without `profile` reads as the file's `default` profile (or its only one), so cadre's existing ledgers stay fresh and replayable.
- `cadre:pr-description` and everything under `plugins/cadre/` stay unchanged; cadre does not bump.
- The ledger keeps its format: `profile` is one more key on new lines. No existing key changes meaning.
- `test_check_plugin.py` pins SKILL.md's and contract.md's wording: change the pin first, watch it go red, then the text.
- Commit subjects: `Break check: …`; the release commit `engineering-review 0.24.0: the five known gaps`.

## Decisions *(my calls, within the spec)*

- **Gap 2:** the spec's words, taken literally: a proof that is not fresh holds no name, and a new proof with its name replaces it. A replay that prints `doesn't compile` keeps the proof stale and listed, so `--stale` stays above `0 stale` until the branch is proven again; nothing is dropped, so no branch is lost. (A first draft dropped the proof; the plan review pointed out that a dropped branch outside the diff vanishes, and that contract.md's own wording was "free a name held by a proof that is not fresh, and let the new proof replace it".)
- **Gap 3:** `--stale --replay` refuses `--profile` (exit 2, `--replay replays each proof with its own profile: leave out --profile`): 0.23.0 accepted `--profile` on any command, so this narrows it, and the PR says so for David. `--partition N` on a replay goes to each profile that names `{partition}`, and is refused only when no profile in the file names it. Before anything runs, the replay refuses a proof whose profile `.break-check.json` no longer has (naming the way out: break it again with `--profile`, whose proof replaces it) and a profile that needs `--partition` without one. The profiles replay one after another, each with its own summary line; a red baseline in a later one comes after the earlier ones' proofs are recorded (documented, not prevented).
- **Gaps 1 and 5, a deletion:** every `-U0` hunk that removes lines, its neighbours the lines just above and below it in the new file (a hunk at `+c,0` sits between `c` and `c + 1`; one at `+c,d` between `c - 1` and `c + d`). `--uncovered` lists it when none of the hunk's added lines is left after the noise and doc filters (git merges a deleted clause with its rewritten comment into one hunk). A deleted file has no deletion.
- **Gap 5:** the listed text is the first deleted line that is neither noise nor inside a doc block, so `end` never stands for the branch; a deletion whose lines are all noise or doc is not listed. Doc lines are judged by scanning the deleted lines from the doc state the current file has just above the deletion.
- **Gap 1:** `--table BASE` diffs the whole tree and keeps the proofs' files in Ruby, so `-M` sees renames: a proof in a file the change only renames is not a row.
- **Both:** BASE goes to git after `--end-of-options`, so a BASE such as `--output=x` is a revision git refuses, not an option.
- **Gap 4:** a cell without a backtick keeps single backticks, so existing tables stay byte-identical.

## Review Focus

- A deletion at the top of a file (git's `+0,0`): listed at line 1; a proof on line 1 covers it, nothing reads line 0 (Task 4, `test_a_deletion_at_the_top_of_a_file`).
- A deletion at the end of a file: listed at the line after the last, covered by a proof on the last line (Task 4, `test_a_deletion_at_the_end_of_a_file`).
- `--table BASE` with an untracked file holding a proof, and with a base git doesn't know (Task 5).
- A swap that starts or ends with a backtick, or holds a run of two (Task 1).
- A cadre ledger, every line without `profile`, in a file whose one profile has no `default` key (Task 2, and Task 6 on cadre's real ledger).
- A deleted clause whose neighbouring comment is rewritten: one hunk, its added line noise (Task 4).

---

### Task 1: `--table` fences a swap that holds a backtick (gap 4)

**Files:** Modify `scripts/break_check/ledger.rb` (`code`), `scripts/test_break_check/ledger_test.rb`, `skills/break-check/SKILL.md` (The ledger), `skills/break-check/contract.md` (Internals 13, Known gaps), `scripts/test_check_plugin.py` if a pin moves.

- [x] **Step 1: red.** `test_table_fences_a_swap_that_holds_a_backtick`: record `from: "x = `ls`"` (file `lib/b.ex` holding it), `to: "x = ls"`; `assert_includes ledger.table, "| `` x = `ls` `` → `x = ls` |"`. Same test, a `from` holding ` `` ` gets a fence of three: `` "``` a``b ```" ``. Run `ruby plugins/engineering-review/scripts/test_break_check/ledger_test.rb -n /backtick/`: fails.
- [x] **Step 2: green.** `Ledger#code(text)`: no backtick → `` "`#{cell(text)}`" `` as now; else the fence is one more backtick than the longest run in `text`, with one space inside each side (CommonMark strips one from each side). All checks green.
- [x] **Step 3: docs.** SKILL.md's ledger paragraph: a swap holding a backtick is fenced with more backticks than it holds. contract.md: Internals 13 says so; its Known gaps entry goes.
- [x] **Step 4:** breaks for the branches in `code`; **commit** `Break check: --table fences a swap that holds a backtick`.

### Task 2: each proof records its profile (gap 3)

**Files:** Modify `scripts/break_check/{profile,run,ledger,cli}.rb`, `scripts/test_break_check/{profile,ledger,cli,run}_test.rb`, `fake_profile.rb` if needed, SKILL.md (The runner, The ledger), contract.md (command line, Internals 11, Known gaps), `test_check_plugin.py` (the pins `"The ledger keeps no profile"`, `"These two are the only hand edits a ledger gets"`).

**Interfaces:**
- `Profile` gains `name` (its first field); `Profiles.build(name, fields, partition:)` sets it.
- `Profiles.load_all(root, partition:) -> [Hash{String => Profile}, String]`: every profile, built, and the name a proof without `profile` takes (`default`, or the only profile). `partition` goes to each profile whose command or env names `{partition}`; given and named by none → `Usage` `.break-check.json: no profile takes --partition`. `Profiles.load` keeps its signature and behaviour and shares the parsing.
- `Ledger#record(brk, line:, tests_failed:, profile:)` writes `"profile" => profile` after `"hashes"`.
- `Run` records `profile: @profile.name`.

- [x] **Step 1: red, one slice at a time:**
  - `test_record_writes_the_fields` (ledger) expects `profile` among the keys, `"exunit"` passed.
  - `test_a_caught_break_records_its_profile` (run): a `FakeProfile` run → the entry's `profile` is `"fake"`.
  - `test_load_all_gives_every_profile_and_the_default` (profile): two profiles with `default: "b"` → `[{"a" => …, "b" => …}, "b"]` (assert keys, names and the default); one profile with no `default` → its name.
  - `test_load_all_gives_the_partition_only_where_it_is_named`: `exunit` and `fake`, partition 3 → exunit's command fills `3`, fake's builds; `fake` alone with partition 3 → `Usage` `no profile takes --partition`.
  - `test_stale_replay_reruns_each_proof_with_its_own_profile` (cli): settings with `fake` (default) and `slow` (`FakeProfile.fields` with a different `failing_test`, e.g. `'^  \d+\) (test .+) \(ATest\)$'`, so its names differ); one proof from each, both made stale; `run_cli(["--stale", "--replay"])` → exit 0, both caught, each entry's `tests_failed` in its own profile's form, each `profile` kept.
  - `test_a_proof_without_a_profile_replays_with_the_default` (cli): a ledger line written by hand without `profile` (copy a recorded entry, delete the key), made stale → caught with the default.
  - `test_a_proof_whose_profile_is_gone_refuses_the_replay`: entry `profile: "old"` → exit 2 naming the proof and `old`, `.invoked` absent.
  - `test_replay_with_a_profile_refuses`: `--stale --replay --profile fake` → exit 2, `leave out --profile`.
  - `test_a_proof_whose_profile_is_gone_is_proven_again_from_a_breaks_file`: the way out the refusal names.
  - `test_a_replay_missing_a_partition_runs_no_profile`: `fake` and a partition-taking `parted`, both stale, no `--partition` → exit 2, nothing ran, the ledger unchanged. `test_a_replay_passes_the_partition_only_to_the_profiles_that_take_it` replays both with `--partition 1`.
  - The existing replay tests that went through `cli` (which adds `--profile fake`) call `run_cli`; `test_stale_replay_that_cannot_run_drops_nothing` strips its proofs' `profile`, so they fall to the default, exunit, which needs `--partition`.
- [x] **Step 2: green.** `CLI.replay` loads with `Profiles.load_all`, groups `stale[:replayable]` by `entry.fetch("profile", default)`, refuses an unknown profile before running, and runs one `Run` per group in ledger order. `parse` refuses `--profile` with `--replay`. The banner says `--profile` picks a profile other than the default, and a replay uses each proof's own. All checks green.
- [x] **Step 3: docs.** SKILL.md "The runner": a repository with more than one profile runs `--uncovered` and its breaks once per profile whose watched paths the change touches (keep the pinned words `once for each profile whose watched paths the change touches`); `--stale --replay` runs once, each proof with the profile that made it. "The ledger": the example line gains `"profile": "exunit"`; a line without it reads as the file's default. contract.md: the command line and Internals 11 say the same; the Known gaps entry goes, with its "These two are the only hand edits" line moved to the doesn't-compile entry until Task 3.
- [x] **Step 4:** breaks; **commit** `Break check: each proof records its profile, and a replay uses it`.

### Task 3: a proof that is not fresh frees its name (gap 2)

**Files:** Modify `scripts/break_check/ledger.rb` (`name_conflicts`, `record`), `scripts/test_break_check/{ledger,run,cli}_test.rb`, `fake_tests.rb` (a mode), SKILL.md (Breaks `name`, Results `doesn't compile`, The ledger), contract.md (Internals 5 and 11, Its tests, Known gaps), `test_check_plugin.py` (the hand-edit pin goes; a pin for the new `name` rule).

- [x] **Step 1: red.** `fake_tests.rb` gains a mode `compile_when_marked`: the compile error when `.compile_marker` exists, else `fail`'s output. `test_a_replay_that_does_not_compile_keeps_the_proof_and_frees_its_name` (cli): `mode_break("compile_when_marked")` caught; `.compile_marker` written and `lib/a.ex` edited; `--stale --replay` → exit 1, `doesn't compile  mode compile_when_marked`, the proof still listed by `--stale`; then a break of the same name with another `to` (`mode=fail`) runs, is caught, and `--stale` ends with `0 stale` and one ledger line. `test_a_name_a_stale_proof_holds_is_free` (ledger): `name_conflicts` is empty for a stale proof's name, and `record` replaces that line. The existing `test_a_name_a_live_proof_in_the_same_file_holds_refuses` and `test_record_replaces_a_same_name_line_only_when_it_is_gone` stay green.
- [x] **Step 2: green.** In `name_conflicts` and `record`, "the proof still holds its name" is `fresh?` rather than `once?`. All checks green.
- [x] **Step 3: docs.** SKILL.md Breaks: `name` is refused while a fresh proof of another swap in that file holds it. Results, `doesn't compile`: on a replay the proof stays stale; write a new break for the branch, which may take its name, and its proof replaces the old. The ledger: a newer proof replaces the one with the same `file` and name that is no longer fresh. contract.md Internals 5 and 11 say so; the Known gaps entry goes.
- [x] **Step 4:** breaks; **commit** `Break check: a proof that is not fresh frees its name`.

### Task 4: `--uncovered` lists deletions (gap 5)

**Files:** Create `scripts/break_check/diff.rb`, `scripts/test_break_check/diff_test.rb`. Modify `scripts/break_check/{uncovered,ledger,cli}.rb` (`cli.rb` requires `diff`), `scripts/test_break_check/{uncovered_test,test_helper}.rb` (`with_git_repo` and `git` move to `RepoHelper`), SKILL.md (After a task's tests are green, Before the PR, Breaks `from`, Results), contract.md (Internals 12, Its tests, Reference implementation's file list, Known gaps), `test_check_plugin.py` (the deleted-lines pins, red first).

**Interfaces:**
- `BreakCheck::Hunk = Data.define(:file, :added, :deleted, :above, :below)`: `added` is `[{file:, line:, text:}]` as `Uncovered` reads lines today, `deleted` the removed lines' text, `above`/`below` the new-file lines just above and below the hunk (see Decisions).
- `BreakCheck::Change = Data.define(:hunks, :untracked)`; `Change#added` is every hunk's added lines and every line of each untracked file; `Change#touched -> Set[[file, line]]` is every added line, and `above` and `below` of each hunk that deletes.
- `BreakCheck::Diff.since(root, base, paths = []) -> Change`: `git diff --no-color --no-ext-diff -M --src-prefix=a/ --dst-prefix=b/ -U0 --end-of-options base -- *paths`, and untracked files under `paths` (the code `Uncovered#added_lines`, `#git`, `#parse` hold today, moved). No `paths` reads the whole tree. Raises `Error` naming git's message when git fails.
- `Ledger#span(entry) -> Range`: the lines `from` covers in the file now, for a fresh entry (moved from `Uncovered#covered_lines`).

- [x] **Step 1: red, `diff_test.rb`:** a deletion in the middle, at the top (`above: 0, below: 1`), at the end; a hunk that removes one line and adds one (neighbours `c - 1` and `c + d`); a deleted file gives no hunk with a file; `touched`; a BASE `--output=x` raises `Error` and writes no `x`.
- [x] **Step 2: red, `uncovered_test.rb`:** `test_a_deletion_is_uncovered_at_the_line_after_it` → `{file: "lib/a.ex", line: <below>, text: "(deleted)   def x(_a), do: :small"}`; `test_a_deletion_of_noise_only_is_left_out` (an `end` alone); `test_the_first_deleted_line_that_is_not_noise_stands_for_it`; `test_a_deletion_beside_a_rewritten_comment_is_listed` (`-  def x(_a)…` with `-  # old` → `+  # new`, one hunk); `test_deleted_doc_lines_are_left_out` (a line inside a `@doc`, and a whole `@doc` block); `test_a_proof_on_the_line_above_or_below_covers_a_deletion` (both, and one two lines away that does not); `test_a_deletion_at_the_top_of_a_file`; `test_a_deletion_at_the_end_of_a_file`; `test_cli_prints_a_deletion`.
- [x] **Step 3: green.** `Uncovered#call` keeps the added lines as today and adds one line per deleting hunk none of whose added lines is left, unless a fresh proof's span holds `above` or `below`; the result sorted by file, then line. All checks green, the existing uncovered tests unchanged but for the moved helpers.
- [x] **Step 4: docs.** SKILL.md "After a task's tests are green" step 1: `--uncovered` lists, under the profile's watched paths, the added lines and each deletion (`<file>:<line> | (deleted) <its first line>`, at the line now after it); read `git diff` only for branches outside those paths. Step 2 keeps the deletion break (`from` the line just above or below, `to` the same with the deleted text put back). Breaks: for a `(deleted)` line, `from` comes from the lines around it. Done criteria and "Before the PR" steps 1–3: what `--uncovered` cannot list is only what lies outside the watched paths. Results: the `--uncovered` line shapes. contract.md Internals 12, Its tests and the file list; the Known gaps entry goes.
- [x] **Step 5:** breaks; **commit** `Break check: --uncovered lists the lines a change deletes`.

### Task 5: `--table BASE` prints only the change's proofs (gap 1)

**Files:** Modify `scripts/break_check/{cli,ledger}.rb`, create `scripts/test_break_check/table_test.rb`, SKILL.md (Before the PR step 3, The ledger, The runner's last sentence), contract.md (command line, Internals 13, Its tests, Known gaps: the section and its Contents entry go), `test_check_plugin.py` (pins: `## Known gaps` and "The ledger keeps no profile" go; `assertNotIn("known gaps", skill.lower())` and `assertNotIn("## Known gaps", contract)`; the belongs pin follows the new words; a pin for `--table <the PR's base commit>`).

**Interfaces:** `Ledger#table(entries = fresh_entries) -> String`; `Ledger#belonging(change) -> [entry]`: the fresh entries whose `span` holds a line of `change.touched` in their file. `--table [BASE]` (OptionParser optional argument; the banner shows it): with BASE, inside `lock_and_recover`, `ledger.table(ledger.belonging(Diff.since(root, BASE)))`.

- [x] **Step 1: red, `table_test.rb`** (git repo, proofs recorded through `Ledger#record`): a proof on an added line is a row, one in a file the change leaves alone is not, and the summary counts 1; a proof on the line just above, and one just below, a deletion are rows, one two lines away is not; a proof in an untracked file is a row; a proof outside every watched path is a row; a proof in a file the change only renames (`git mv`, committed) is not; `--table` alone still prints every fresh proof; `--table no-such-ref` exits 2 naming it.
- [x] **Step 2: green.** All checks green.
- [x] **Step 3: docs.** SKILL.md "Before the PR" step 3 runs `<runner> --table <the PR's base commit>`; "The ledger": a proof belongs to a change when its `from` spans a line the change adds or changes, or sits on the line just above or below a line it deletes; `--table BASE` prints the fresh proofs that belong to the change since BASE, `--table` alone every fresh one. contract.md: command line, Internals 13, Its tests; Known gaps is empty, so the heading and its Contents line go.
- [x] **Step 4:** breaks; **commit** `Break check: --table BASE prints only the change's proofs`.

### Task 6: release, and a cadre ledger

- [x] **Step 1:** engineering-review `0.24.0` in `plugins/engineering-review/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. All checks green, `ruby script/check_version_bumps.rb origin/main` prints `OK`, `~/.local/bin/claude plugin validate plugins/engineering-review` passes. **Commit** `engineering-review 0.24.0: the five known gaps`.
- [x] **Step 2: cadre's ledger.** In the scratchpad: `git clone -q --shared ~/Code/cadre <scratch>/cadre` and check out `~/Code/cadre/.claude/worktrees/awesome-fermat-5ce71b`'s HEAD (`399dfcfb`, a clean worktree, base `dc13fb49`), then copy in its git-ignored `.breaks/ledger.jsonl`; its `.break-check.json` and `.breaks/ledger.jsonl` (28 proofs, none with `profile`) come with it. Read-only on the worktree itself. In the copy, the new runner: `--stale` gives the same lines as the 0.23.0 runner (`~/.claude/plugins/cache/cadre/engineering-review/0.23.0/scripts/break_check.rb`), `--table` the same bytes, `--uncovered <base>` the same lines, and `--table <that worktree's base>` a subset each of whose rows names a file `git diff --name-only <base>` lists. Record the counts for the PR.
- [x] **Step 3: before the PR,** in this worktree: `ruby $R --stale --replay` until `0 stale`, `ruby $R --uncovered d1c860c` lists no line that holds a branch, `ruby $R --table d1c860c` is the PR's Break checks part.

### Task 7: reviews and the PR

- [ ] **Step 1:** review rounds with two lenses, engineering-principles rule by rule and writing-for-agents (SKILL.md, contract.md, the plan): round 1 the whole branch from `d1c860c`, each later round only the delta, earlier rulings standing; stop at a round clean on both. Rerun Task 6 step 3 after any fix. Round 1 (the whole branch at `bb508e8`): engineering-principles 1 Important, a path git quotes dropped its hunks silently, and 6 Minor; writing-for-agents 2 Important, a `(deleted)` line read as a branch to break and an ambiguous "it" for its `from`, and 8 Minor; all fixed but the duplicate Break-checks sentence in "The runner", pinned by `test_no_skill_or_agent_names_the_pr_standard_by_its_old_name`, and the cadre docs' bare `--table`, which cadre's frozen wording keeps. Round 2 (the delta to `35a0fe7`): engineering-principles 1 Important, an untracked file whose name git quotes vanished, fixed with `ls-files -z`, and 3 Minor; writing-for-agents 1 Important, the done criteria counted `(deleted)` lines among those that must hold no branch, and 4 Minor; all fixed. Round 3 (the delta to `560c1dd`): engineering-principles 0 Important and 1 Minor, an untracked name that is not UTF-8 was scrubbed and its file lost on Linux, fixed by scrubbing only the diff text (its test runs on Linux, where CI runs, and skips on macOS, which refuses such a name; the scrub dropped from `Diff.git` is proven by that test alone, and `--uncovered` lists nothing for it, since the line's remaining conversion has its own proof); writing-for-agents 0 Important and 3 Minor; all fixed. Round 4 (the delta to `366d3b2`): engineering-principles 1 Important, `split("\0")` raised on the name that is not UTF-8, so the Linux test would have errored, fixed with `each_line("\0", chomp: true)`; writing-for-agents 0 Important and 4 Minor; all fixed.
- [ ] **Step 2:** the spec's Increment 3 status line `- [x] PR #<n>`; the PR described to `cadre:pr-description`, titled `Break check (3/5): the five known gaps`, its Break checks part `ruby $R --table d1c860c`. CI green.
