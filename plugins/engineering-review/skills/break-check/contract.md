# The runner's contract

What the break-check runner does: the one this plugin ships, and any runner a repository still keeps of its own. Read it before changing the runner or writing a `.break-check.json`. What the runner prints, its exit codes, the breaks file, the ledger, the table and the words fresh, stale and gone are in [SKILL.md](SKILL.md): a runner prints, exits and writes as SKILL.md shows, so the recipes, the PR's table and the review read every repository's runs the same way.

## Contents

- [The command line](#the-command-line)
- [Internals](#internals)
- [.break-check.json](#break-checkjson)
- [Its tests](#its-tests)
- [Known gaps](#known-gaps)
- [Reference implementation](#reference-implementation)

## The command line

Run from the repository root:

- `<runner> BREAKS.json` breaks each branch in the file, one at a time, and records what is caught.
- `<runner> --stale` lists stale and gone proofs; `--stale --replay` reruns the stale ones from the ledger.
- `<runner> --uncovered BASE` lists the changed lines since `BASE` that no fresh proof covers.
- `<runner> --table` prints the fresh proofs as the PR's table.
- `--profile NAME`, on any command, picks a profile other than the file's `default`; `--partition N` is for a profile whose `command` or `env` names `{partition}`: required only when a test runs, and refused on any command by a profile that doesn't name it.
- `<runner> --help` lists every flag.

Every command reads `.break-check.json` first, and exits 2 when it is missing or invalid, or names no such profile, so a run outside the root never reads as an all-clear. The runner exits 2 on Ruby older than 3.2 too, before it loads anything else. Everything the runner keeps is under `.breaks/`, in the repository it runs in and never beside the runner itself, and the change that adopts the runner git-ignores it. One command at a time.

## Internals

1. **Lock, then recover.** Every command takes a lock the operating system drops when the process dies (`flock` on `.breaks/lock`), then recovers what a killed run left before reading any file, and says so loudly: `RESTORED <file> FROM A KILLED RUN`.
2. **Journal.** Before each swap, write `{path, original, hash of the broken text}` to `.breaks/journal/`, whole or not at all (a temp file, then a rename). A file is restored only while it still holds that break, at the end of a swap and when recovering; a file edited since is left alone with its entry, and the run exits 3 naming the entry. An entry that cannot be read is named, never skipped.
3. **The test run in flight** is recorded in `.breaks/child`. A run killed outright leaves it; the next run names it with the command to stop it, and never kills it, since a pid can be reused.
4. **Check first.** For each break: the file and each test file exist, `tests` is a non-empty list, `to` differs from `from`, `from` occurs exactly once, and no two breaks in one file share a name. A miss says how many times `from` occurred: 0, or each occurrence with its line. Report every problem and run nothing.
5. **Names.** A break's name is refused as the Breaks section of SKILL.md says.
6. **Skip what is proven.** A break whose exact swap in its file has a fresh proof runs nothing.
7. **Green baseline per set.** Run each distinct set of listed tests unbroken, in a fixed order (the profile's command fixes it, such as with a seed); a red set stops the run with the failing names, or the output's tail.
8. **One at a time.** Swap, run the break's tests with a per-break timeout in their own process group, restore. A signal or a timeout stops that group; the runner puts the previous signal handlers back.
9. **Outcomes fail closed,** checked in this order:
   1. a timeout: `inconclusive`;
   2. the compile-error pattern: `doesn't compile`;
   3. the infrastructure pattern: rerun once, then `inconclusive`;
   4. the refusal pattern (another test run holding the database or the partition): `inconclusive`;
   5. a failing exit that names failing tests: `caught`, with those names;
   6. a passing exit: `NOT CAUGHT`;
   7. anything else: `inconclusive`, with the output's last lines.
10. **Ledger.** Each `caught` is written once its restore is verified, so a killed run loses nothing. The ledger is rewritten whole (a temp file, then a rename).
11. **Stale.** `--stale --replay` names the gone proofs, reruns the stale ones as the ledger holds them, and only then drops the gone ones, so a replay that cannot run loses nothing.
12. **Uncovered.** The lines added since `BASE` under the watched paths, untracked files included, minus the lines a fresh proof's `from` spans, noise lines and doc-block lines.
13. **Table.** In the shape SKILL.md shows.
14. **Exit codes** as SKILL.md gives them.

## .break-check.json

At the repository root, committed. It holds the repository's settings, so the runner is the same everywhere. This one is the cadre marketplace's, which breaks the runner's own code:

```json
{
  "profiles": {
    "minitest": {
      "command": ["ruby", "-e", "ARGV.each { require File.expand_path(_1) }", "{files}"],
      "failing_test": "^\\s+\\d+\\) (?:Failure|Error):\\n(\\S+#test_\\w+)",
      "compile_error": "SyntaxError",
      "timeout": 120,
      "watched": ["plugins/engineering-review/scripts/break_check.rb", "plugins/engineering-review/scripts/break_check"],
      "noise": "\\A\\s*(?:#(?!\\{).*|end|\\)|\\]|\\}|)\\s*\\z"
    }
  }
}
```

`profiles` names one profile per test suite, each with these fields:

| Field | Required | Holds |
|---|---|---|
| `command` | yes | the test command as a list of strings. `{files}` is one whole argument after the program, and the break's test files take its place, one argument each. The command runs the tests in a fixed order. |
| `env` | no | the command's environment, names to strings |
| `failing_test` | yes | a pattern whose first group captures each failing test's name; it may span lines |
| `compile_error` | yes | the output of a break that doesn't compile |
| `infrastructure` | no | the output of a broken test setup: the break reruns once, then reads `inconclusive` |
| `refusal` | no | the output of another test run holding the database or the partition: `inconclusive` |
| `timeout` | yes | seconds per test run, a positive number |
| `watched` | yes | every path that holds branches, each one existing: `--uncovered` looks only there |
| `noise` | yes | changed lines that hold no branch (a closing keyword, a comment) |
| `doc_open`, `doc_close` | no, but together | the lines that start and end a doc block, whose lines hold no branch |

- `failing_test`, `compile_error`, `infrastructure`, `refusal`, `noise`, `doc_open` and `doc_close` are patterns: Ruby regular expressions written as JSON strings, their backslashes doubled. Flags go inline, as in `(?m)`.
- `{partition}`, anywhere in `command` or `env`, becomes the N of `--partition N`. A profile that names it needs `--partition` to run tests; one that doesn't refuses `--partition`.
- `default` names the profile a command uses when `--profile` is left out. It is required when the file holds more than one profile; with one, that one is used.
- Any other key, a required field missing, a value of the wrong kind or a pattern that doesn't compile: the runner exits 2 naming the profile and the field.

## Its tests

The runner's Minitest tests are in `scripts/test_break_check/`, against a stub test command, so they run in seconds:

- a break caught, and one not caught;
- a break that doesn't compile;
- a miss (a `from` found 0 times, and twice);
- a red baseline;
- a run killed mid-break, then recovered by the next command;
- the lock held by another run;
- the ledger: a proof recorded, made stale, replayed, gone and dropped;
- `--uncovered` and `--table` on a small git repository;
- `.break-check.json`: each refusal, the choice of profile, `{files}` and `{partition}`;
- an old Ruby refused.

Once its tests are green, break-check the runner's own code with the runner of the same checkout, as the cadre marketplace's `AGENTS.md` says.

## Known gaps

- A stale proof whose replay prints `doesn't compile` stays stale: its branch needs a new break, which cannot take the old name while the old `from` still occurs once, and nothing replaces the old proof. `--stale` then never reaches `0 stale`. Until runners free a name held by a proof that is not fresh, and let the new proof replace it, the old line is dropped by deleting it from the ledger by hand.
- `--table` takes no base, so it prints the proofs of every change in the worktree; `cadre:pr-description` says which rows a PR drops.
- The ledger keeps no profile, so `--stale --replay` reruns every stale proof with the one profile it is given, and a stale proof from another suite stops it red. Until runners record the profile, replay when only one suite's files changed, or move the other suite's stale lines out of the ledger by hand for the replay and put them back after it. These two are the only hand edits a ledger gets.
- `--uncovered` lists added lines only, so a branch narrowed only by deleting lines never shows there; SKILL.md says to break it all the same.
- `--table` wraps `from` and `to` in single backticks, so a swap that holds a backtick (a template literal, a raw string) breaks its cell. Until runners fence a cell with more backticks than it holds, check such a row against the ledger itself.

## Reference implementation

This plugin's `scripts/break_check.rb` and the files under `scripts/break_check/` (`breaks.rb`, `cli.rb`, `ledger.rb`, `profile.rb`, `run.rb`, `uncovered.rb`, `workspace.rb`), with their tests in `scripts/test_break_check/`, ported from cadre's runner (djeusette/cadre#159). It is Ruby 3.2 or later, with the standard library only. Read it when the contract leaves a choice open; where the two disagree, the contract wins and the runner is fixed.
