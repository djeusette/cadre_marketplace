---
name: break-check
description: Break check: breaks each branch a change adds or changes and records the proof. Use when a task's tests are green, before a PR, or to write a repository's .break-check.json.
---

# Break check

A test is real only if it fails when its code breaks. A break check shows it: break one **branch** on purpose, see a named test fail, undo the break. EP-G4 asks it of every branch a change adds or changes, and says what a branch is. This plugin ships the **runner** that does the breaking and keeps the record, reading each repository's settings from its `.break-check.json`, so the check costs few tokens and each branch is proven once.

- **Break:** the smallest change to one branch that still compiles (see [Breaks](#breaks)). Its **swap** is the pair `from` → `to`: the exact text it replaces, and the text it puts there.
- **Proof:** a line in the **ledger**, written by the runner alone, when a test it names failed on a break, on tests that ran green just before. A proof starts from green tests: the red step of TDD fails because the code is not there yet, not because of the branch.
- **Fresh:** a proof whose file and test files are unchanged since it ran, and whose `from` still occurs exactly once.
- **Stale:** a proof whose file or one of whose test files changed since; the runner replays it.
- **Gone:** a proof whose `from` no longer occurs exactly once, or whose test file is missing; its branch needs a new break.

## Before you start

1. `ruby --version` prints Ruby 3.2 or later. An older one (macOS's `/usr/bin/ruby` is 2.6) makes the runner exit 2: put a newer Ruby first on `PATH`.
2. The repository root holds `.break-check.json`, or a runner of the repository's own. With neither, follow [The runner](#the-runner).

## Run it in your own context

Whoever wrote the code runs its breaks, in the same session: a fresh agent's starting context is most of what a break check costs. The runner prints one line per break: read those lines, not the test output.

## The runner

Look for a committed runner (a `break_check` script its `AGENTS.md` or a README names) first: while a repository still keeps one, a committed runner of the repository's own wins, and `<runner>` below is that one, called as its `AGENTS.md` or README says.

Otherwise, `<runner>` is `ruby <this skill's base directory>/../../scripts/break_check.rb`, run from the repository root; the session shows the base directory when this skill loads. It reads the repository's profiles from `.break-check.json` at the root; before changing the runner itself, read [contract.md](contract.md), which says what it does. `<runner> --help` lists its flags: `--profile NAME` picks a profile other than the file's `default`, and `--partition N` is required by a profile whose `command` or `env` names `{partition}`, so its tests run beside other sessions': pick an N no other session uses. A repository with more than one profile (such as the app's and a script folder's) runs `--uncovered` and its breaks once for each profile whose watched paths the change touches, naming it with `--profile`; `--stale --replay` runs once and replays each proof with the profile that made it.

A repository with neither gets `.break-check.json` before its first break, committed with `.breaks/` in its `.gitignore`. Write one profile per test suite, in the fields [contract.md's `.break-check.json`](contract.md#break-checkjson) gives, its patterns copied from what its tests really print: run one failing test and one that doesn't compile, and read the output. Each profile's check is one break of a branch that already has a test, run with `--profile <name>`: `caught` shows the profile reads its suite. Breaks go through the runner, since only it records a proof a later step or a review can read. The PR description's Break checks part, as `cadre:pr-description` gives it, comes from the runner's `--table`.

## After a task's tests are green

1. `<runner> --uncovered <the task's base commit>` lists the changed lines no fresh proof covers. It lists added lines under the profile's watched paths only, so read `git diff <the task's base commit>` for deleted lines, and for branches outside those paths, too.
2. Write one break per branch on those lines into a breaks file under `.breaks/`, such as `.breaks/task-3.json`. A proof covers every line its `from` spans, so a line holding several branches (each value in a guard list) gets a break for each. A branch the change narrows only by deleting lines (a value dropped from a guard list) gets a break too: its `from` taken from the lines around the deletion, its `to` the same lines with the deleted text put back.
3. `<runner> .breaks/task-3.json`. The runner checks every swap first and runs nothing on a miss, so let it do the checking.
4. For each `NOT CAUGHT`: write a test, add its file to the break's `tests` when it is not listed, then rerun the file: its `caught` line is the test failing on the break.

Done when the run exits 0, every line `--uncovered` still lists holds no branch, and each branch `--uncovered` cannot list (narrowed only by deleting lines, or outside the watched paths) has a fresh proof. Then commit: the ledger is git-ignored and stays in this worktree.

## Before the PR

In the worktree that holds the ledger (a scratch worktree has none):

1. `<runner> --stale --replay` reruns every stale proof and drops the gone ones, whose branches `--uncovered` then lists again, except a branch `--uncovered` cannot list: break it again from the `gone` line the replay printed.
2. `<runner> --uncovered <the PR's base commit>`, and `git diff <the PR's base commit>` for the branches it cannot list (deleted lines, paths outside the watched ones) that `--table` shows no fresh proof for; break those as in steps 2–4 of "After a task's tests are green". A test added here can make other proofs stale: rerun step 1 until `<runner> --stale` ends with `0 stale`.
3. Once `--stale` ends with `0 stale`, every line `--uncovered` lists holds no branch, and each branch `--uncovered` cannot list (narrowed only by deleting lines, or outside the watched paths) has a fresh proof, `<runner> --table` prints the Break checks part of the PR description (`cadre:pr-description`).

Done when the table is printed after the last break.

## Breaks

A breaks file is a JSON array, one object per branch:

```json
[{"name": "same second is not after", "file": "lib/cadre/source_control/change_requests.ex",
  "from": "DateTime.compare(head_committed_at, submitted_at) == :gt",
  "to": "DateTime.compare(head_committed_at, submitted_at) != :lt",
  "tests": ["test/cadre/source_control/change_requests_test.exs"]}]
```

- `name` is the branch's identity in its file: unique among the file's breaks, and refused while a fresh proof of another swap in that file holds it: a proof that is not fresh frees its name, and the new proof replaces it. A proof of the same swap never blocks it.
- `from` is the shortest text found exactly once in `file`, on one line unless the branch needs more: copy it from the `--uncovered` line.
- `to` is the smallest change to that one branch, one that still compiles: flip the condition, drop the guard value, delete the cast, swap the clause order. A break that raises, empties or replaces a body proves nothing: any test catches it.
- `tests` lists only the test files that cover the branch: the fewer, the faster.

## Results

A run prints one line per break as it happens, then a summary line (`<n> caught, <n> not caught, <n> doesn't compile, <n> inconclusive`), one per profile on a replay:

| Line | Means | Do |
|---|---|---|
| `caught  <name>  ← <tests>` | a proof, now in the ledger | nothing |
| `proven  <name>  (fresh in the ledger)` | a fresh proof of this exact swap was already there; nothing ran | nothing |
| `NOT CAUGHT  <name>` | no test notices the break | write the test, list its file in the break's `tests`, and rerun the file, so the runner shows it failing on the break; on a replay, put the proof's swap in a breaks file with the test files that now cover it, and its new proof replaces the old |
| `doesn't compile  <name>` | not a valid break | write another break for that branch; on a replay the proof stays stale until it is proven again, and the new break may take its name |
| `inconclusive  <name>  (<reason>)` | a timeout, the infrastructure, another test run, or output the runner cannot read | rerun it |

`--stale` prints `replayable <file>:<line> <name>` or `gone <file>:<line> <name>` per proof, then `<n> stale`, counting both. `--uncovered` prints `<file>:<line> | <text>` per line, then `<n> changed lines have no fresh proof`.

## Exit codes

- **0** every break was caught or already `proven`, or nothing is left.
- **1** something is left: a break not caught, one that doesn't compile or is inconclusive, a stale or gone proof listed, a line no proof covers, a gone proof dropped. A normal end of `--uncovered`, `--stale` and `--stale --replay`: read the lines.
- **2** the runner refused and broke nothing: no `.break-check.json` at the root or a bad one, an unknown profile, a `--partition` missing or not taken, a stale proof whose profile the file no longer has (break it again with `--profile`, and its new proof replaces it), Ruby older than 3.2, the lock is held, a swap missed, a bad breaks file, tests red before any break, a bad command line, an unexpected error.
- **3** a file could not be restored, or changed while it held a break. The message names the journal entry that holds the original. When the file differs from the original only by the break, put the original back; when someone edited it meanwhile, undo the break by hand and keep their edit. Then delete the entry, or every command exits 3 again.

## The ledger

`.breaks/ledger.jsonl`, git-ignored, one JSON object per line, one line per proof:

```json
{"name": "same second is not after", "file": "lib/cadre/source_control/change_requests.ex", "line": 42,
 "from": "DateTime.compare(head_committed_at, submitted_at) == :gt", "to": "DateTime.compare(head_committed_at, submitted_at) != :lt",
 "tests_failed": ["test a commit in the same second is not after the review (Cadre.SourceControl.ChangeRequestsTest)"],
 "hashes": {"lib/cadre/source_control/change_requests.ex": "<sha256>", "test/cadre/source_control/change_requests_test.exs": "<sha256>"},
 "profile": "exunit"}
```

`line` is where `from` was when the break ran. `hashes` holds the SHA-256 of `file` and of each test file, which tells fresh from stale. `profile` names the profile that ran the break; a line without one reads as the file's `default` profile. A newer proof replaces the one with the same swap in the same file, and one with the same `file` and name that is not fresh.

A proof **belongs** to a change when its `from` spans a line the change adds or changes, or sits next to a line it deletes. `<runner> --table` prints every fresh proof in this worktree, whichever change it belongs to, in this shape, `|` escaped as `\|`, a newline as `⏎`, and a swap that holds a backtick fenced with more backticks than it holds:

```markdown
<details><summary>Break checks (1)</summary>

| Branch | Swap | Caught by |
|---|---|---|
| lib/cadre/source_control/change_requests.ex:42 | `DateTime.compare(head_committed_at, submitted_at) == :gt` → `DateTime.compare(head_committed_at, submitted_at) != :lt` | test a commit in the same second is not after the review (Cadre.SourceControl.ChangeRequestsTest) |

</details>
```
