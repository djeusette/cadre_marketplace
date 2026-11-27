# Break check: one shared runner — design

> Not tracked in Cadre, as David chose (2026-11-27). Plan each increment with `superpowers:writing-plans`, one at a time; its status line becomes `- [x] PR <repo>#<n>` when that PR opens.

The successor of colette-club's `docs/superpowers/specs/2026-11-25-break-check-design.md`, whose unshipped work it takes over before the cadre marketplace move's increment 8 deletes that spec. Brainstormed with David on 2026-11-27, then read by a builder check, whose points are folded in. The calls I made are marked *(my call)*.

**Words.** A *break* swaps one branch's text (`from` → `to`) and runs the tests that should catch it. A *proof* is the ledger line the runner writes when a named test failed on a break. The *runner* is the program that does both. A *profile* is one test suite's settings. `engineering-review:break-check` is the skill; `contract.md` beside it states what a runner does.

## Intent

The break check proves each branch a change adds has a real test. It works, and it is cheap once a runner exists: cadre's runner (djeusette/cadre#159, `script/break_check.rb`, about 2,100 lines with its tests) costs 44 % of the old tokens per break. But the skill today asks each repository to write its own runner, in its own language, from `contract.md`. That is the expensive part, done once per repo, and nine slightly different runners would drift from the contract and from each other.

David decided (2026-11-27): one runner, shipped in `engineering-review`, used by every team repo. Each repo keeps only its settings.

## End goal

Every team repo (cadre, colette-api, kinfield, colette-app, rooms-app, admin-app, club-mobile, cadre_marketplace, colette-marketplace) breaks its branches with `engineering-review`'s runner and a committed `.break-check.json`, and a plan made with `cadre:writing-plans` runs the break check in each task and before the PR. No repo carries a runner of its own.

## Goals

- One runner in `engineering-review`, ported from cadre's, behaving as `contract.md` says.
- A repo adopts it by committing `.break-check.json` and a Skills-table row, nothing else.
- cadre's existing proofs in `.breaks/ledger.jsonl` stay fresh across the switch.
- The five known gaps in `contract.md` are fixed in the shared runner.
- `cadre:writing-plans` writes the break check into every plan of a repo whose Skills table lists `engineering-review:break-check`.

## Non-goals

- Changing what a break, a proof or the ledger is. The contract stands; the port is a port.
- Parallel breaks, generated mutants, the review running breaks: the original spec's non-goals stand.
- A runner in another language. Ruby, because cadre's runner is Ruby and reviewed.

## Anti-goals

- A ledger that claims a proof that never ran.
- A runner that leaves a break in the code, even after it is killed.
- A repo's own settings inside the plugin. The plugin holds behaviour; `.break-check.json` holds everything repo-specific.
- A change in behaviour hidden in the port. Increment 1 moves cadre's runner as it is; the gaps are fixed in increment 3, each with its own tests.
- `cadre` depending on `engineering-review`. `cadre:writing-plans` names `engineering-review:break-check` only for a repo whose Skills table lists it.

## Constraints

- **Ruby 3.2 or later** on the machine that runs breaks. The skill's "Before you start" checks `ruby --version`, and the runner exits 2 naming the version it needs. Flutter, Vitest and Python repos need Ruby only to run breaks.
- **Every merge to the cadre marketplace's `main` is a release**: a PR that changes `plugins/<name>/` bumps that plugin's version (`script/check_version_bumps.rb` in CI).
- **cadre's skills cite no EP IDs and never write "colette"**; tests enforce both. cadre depends only on `superpowers@claude-plugins-official`.
- **The runner never writes to its own directory**: a team repo runs the installed copy, whose path differs per machine. Everything it writes (`.breaks/`, the ledger, the journal, the lock) is under the repository it runs in, as today.
- **`check_plugin.py`** checks `engineering-review`'s files; a new kind of file under `scripts/` must pass it, or the check learns it in the same PR.

## Approaches

1. **Port cadre's runner into `engineering-review`, settings per repo in `.break-check.json` (chosen).** One reviewed implementation; a repo adopts it in a few lines.
2. **Each repo writes its own runner from `contract.md`** (the skill today). Nine implementations to write, test and keep in step.
3. **A rewrite in a language every machine has** (Python, or Node). Throws away a reviewed, measured runner for a dependency most machines already meet.

David chose 1.

## The design

### The runner

- Lives in `plugins/engineering-review/scripts/break_check.rb`, with its library under `plugins/engineering-review/scripts/break_check/` and its Minitest tests under `plugins/engineering-review/scripts/test_break_check/` *(my call: beside the Python scripts, out of the skills folder)*.
- Is invoked as `ruby <engineering-review's scripts dir>/break_check.rb`, run from the repository root. The skill gives the path from its own base directory, which the session shows when the skill loads (`<skill dir>/../../scripts/break_check.rb`).
- Keeps cadre's command line: a breaks file, `--stale [--replay]`, `--uncovered BASE`, `--table`, `--partition N`, `--profile NAME`, `--help`. `--profile` picks a profile from `.break-check.json`; with one profile it may be left out.
- Refuses (exit 2, naming what is wrong) when `.break-check.json` is missing or invalid, when the profile it names isn't there, and when Ruby is older than 3.2.
- Its tests run in the cadre marketplace's CI, beside `engineering-review`'s Python tests, and in `AGENTS.md`'s "Checks".
- In the cadre marketplace, the runner's own code is broken with the worktree's copy, `ruby plugins/engineering-review/scripts/break_check.rb --profile minitest`, so a change to the runner is checked by the runner it ships. Increment 1 commits this repo's `.break-check.json` with that `minitest` profile *(my call: the builder check found the runner had nothing to break-check itself with until increment 5)*.
- **The port's proofs.** The ported Minitest tests come over unchanged and must pass. They count as the port's proof, since cadre's runner proved those branches in djeusette/cadre#159 and the port changes their paths, not their code (David's call, 2026-11-27). Every branch the port adds or changes, such as the profile loader, gets a break through the runner.

### `.break-check.json`

At the repository root, committed. It holds one or more profiles: what cadre's `Profile` holds today, as data.

```json
{
  "profiles": {
    "exunit": {
      "command": ["mise", "exec", "--", "mix", "test", "--seed", "0", "{files}"],
      "env": { "MIX_TEST_PARTITION": "{partition}" },
      "failing_test": "^\\s+\\d+\\) (test .+ \\([\\w.]+\\))$",
      "compile_error": "== Compilation error in file",
      "infrastructure": "too_many_connections",
      "refusal": "Another mix test run is using",
      "timeout": 300,
      "watched": ["lib"],
      "noise": "\\A\\s*(?:#(?!\\{).*|end|do|\\)|\\]|\\}|)\\s*\\z",
      "doc_open": "\\A\\s*@(?:moduledoc|doc|typedoc)\\s+\"\"\"\\s*\\z",
      "doc_close": "\\A\\s*\"\"\"\\s*\\z"
    }
  }
}
```

- `command` is an argument list; `{files}` expands to the break's test files, `{partition}` to the N of `--partition N`. A profile whose command or env names `{partition}` requires `--partition`; one that doesn't, refuses it.
- The patterns are Ruby regular expressions as strings. `failing_test` captures the failing test's name in its first group and may span lines.
- `infrastructure`, `refusal`, `doc_open` and `doc_close` are optional.
- `"default": "<profile>"` names the profile used when `--profile` is left out. It is required when the file holds more than one profile *(my call)*.
- A single run with a profile that doesn't take `{partition}` refuses `--partition`. A replay of mixed profiles passes `--partition` only to the profiles that take it *(my call)*.

### The ledger

`.breaks/ledger.jsonl` keeps cadre's format, so cadre's existing proofs stay fresh across increment 2. Increment 3 adds each proof's profile name; a line without one is read as the file's `default` profile *(my call)*.

### The skill

`engineering-review:break-check` changes with increment 1:

- "The runner" says the plugin ships it and how to call it. A repo adopts it by committing `.break-check.json`. A repo with neither gets `.break-check.json` written before its first break, following the shape above, with its tests' real output read to write the patterns.
- `contract.md` becomes the shared runner's documentation: the same behaviour, written as what this runner does, with the profile file's fields. "Reference implementation" points at the plugin's runner. "Known gaps" lists what increment 3 fixes, until it does.
- "Before you start" checks Ruby 3.2.
- While cadre still has its own runner (until increment 2 merges), a committed repo runner wins over the plugin's *(my call: so increment 1 deploys alone)*.

### The five gaps (increment 3)

From `contract.md`'s Known gaps:

1. `--table BASE`: only the proofs whose `from` spans a line the change since `BASE` adds or changes, or sits on the line just above or below a line it deletes (the rule `cadre:pr-description` gives for a row that belongs). The skill's before-the-PR recipe passes the PR's base. `cadre:pr-description` doesn't change: its rule for dropping other changes' rows still holds, and on a `--table BASE` table it drops none *(my call: keeps cadre free of the runner's flags)*.
2. A stale proof whose replay doesn't compile frees its name, so its branch can take a new break.
3. Each proof records its profile, and `--stale --replay` replays each with its own.
4. `--table` fences a swap that holds a backtick.
5. `--uncovered` lists a branch narrowed only by deleting lines: for each deletion under the watched paths whose lines aren't all noise, one line `<file>:<line> | (deleted) <first deleted line>`, at the line now just after the deletion. A fresh proof covers it when its `from` spans the line just above or below the deletion *(my call)*. The skill's recipes stop asking to read `git diff` for deleted lines.

Each gets its tests, red first, and its breaks through the worktree's runner. `contract.md` drops each from Known gaps as it ships.

### The plans (increment 4)

`cadre:writing-plans`, for a repo whose Skills table lists `engineering-review:break-check`:

- "Before you start" checks the skill and Ruby 3.2 are there.
- A repo with no `.break-check.json`: the plan's first task writes it, with a break of one existing branch run as its check.
- Each task: after green, the implementer runs the break check in its own session.
- The plan's final review: `--stale --replay`, then `--uncovered <the PR's base>`, then breaks for the lines it lists, then `--table` for the PR.

The cadre skill states these steps in its own words, without EP IDs.

### Each repo's adoption (increments 2 and 5)

One PR per repo:

- `.break-check.json`, its profiles written from its own test runner's output;
- a Skills-table row: `engineering-review:break-check` | adding or changing a branch, and before a PR | `claude plugin install engineering-review@cadre`, with the agent-skills test's row count raised where there is one;
- `.breaks/` in `.gitignore`;
- a check: one real branch broken and caught through the plugin's runner, recorded in the PR.

The stacks: ExUnit (cadre, colette-api, kinfield's umbrella with its two partitions), Vitest (colette-app, rooms-app, admin-app), `flutter test` (club-mobile), Python `unittest` (cadre_marketplace, whose `minitest` profile came in increment 1), Minitest and its TypeScript scripts' tests (colette-marketplace). cadre's PR also deletes `script/break_check.rb`, `script/break_check/`, `script/test/` and `script/README.md`, and points `AGENTS.md` and its Checks at the plugin's runner.

## Left to the builder

- The runner's file layout under `scripts/`, its help text and its exit messages, within cadre's behaviour.
- How regex flags (multiline) are written in `.break-check.json`.
- Each repo's exact patterns and timeouts.
- Version numbers, following each marketplace's release steps.
- Whether cadre's memory notes (`break-check-before-prs`, `review-against-skills-before-pr`) change, which is David's to say once increment 4 ships.

## Increments

### Increment 1 — The shared runner in `engineering-review` (cadre marketplace)

- **Delivers:** `ruby <scripts>/break_check.rb` works in any repo with a `.break-check.json`, as cadre's runner does in cadre. The skill and `contract.md` describe it.
- **Deployable alone:** no repo has a `.break-check.json` yet, and a committed repo runner still wins. cadre keeps using its own.
- **Consumers:** none.
- **Code files:** about 10 — `plugins/engineering-review/scripts/break_check.rb`, the six files under `scripts/break_check/`, `plugins/engineering-review/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.github/workflows/<checks>.yml`, and this repo's `.break-check.json`. The port is larger than the preferred ten files' worth of lines, and can't be smaller: the runner works as one unit.
- [ ] Not shipped

### Increment 2 — cadre uses the shared runner (cadre)

- **Delivers:** cadre breaks its branches with the plugin's runner, and its own runner is gone.
- **Deployable alone:** the shared runner shipped in 1; cadre's ledger format is unchanged, so its proofs stay fresh.
- **Consumers:** anyone with a cadre branch that calls `ruby script/break_check.rb`: after a merge of `main` they call the plugin's runner, as the skill says.
- **Code files:** cadre's `script/break_check.rb` and `script/break_check/` (deleted), `.break-check.json`; the tests and README go with them.
- [ ] Not shipped

### Increment 3 — The five known gaps (cadre marketplace)

- **Delivers:** `--table BASE`, a freed name after a failed replay, the profile per proof, fenced backticks, branches narrowed by deletion.
- **Deployable alone:** a ledger line without a profile reads as the default, so existing ledgers keep working.
- **Consumers:** cadre (adopted in 2). `cadre:pr-description` is unchanged.
- **Code files:** about 6 — the runner's library files the gaps touch, `plugin.json`, `marketplace.json`.
- [ ] Not shipped

### Increment 4 — Plans run the break check (cadre marketplace)

- **Delivers:** a plan made with `cadre:writing-plans` in a repo whose Skills table lists `engineering-review:break-check` writes `.break-check.json` first when it's missing, breaks each task's branches, and replays before the PR.
- **Deployable alone:** a repo without the row plans as today.
- **Consumers:** cadre (which lists the row from increment 2).
- **Code files:** 2 — `plugins/cadre/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (the skill and its tests are docs and tests).
- [ ] Not shipped

### Increment 5 — The other eight repos adopt it (colette-api, kinfield, colette-app, rooms-app, admin-app, club-mobile, cadre_marketplace, colette-marketplace)

- **Delivers:** each repo breaks its branches with the shared runner, and its plans run the break check.
- **Deployable alone:** each repo's PR is its own; a repo not yet switched plans as today.
- **Consumers:** each repo's own sessions.
- **Code files:** 1 or 2 per repo — `.break-check.json`, `.gitignore` (the Skills table and its test are docs and tests).
- [ ] Not shipped
