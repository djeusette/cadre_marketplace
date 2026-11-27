# The team repos install from the cadre marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** each team repo enables `engineering-review` and `security-audit` from the cadre marketplace, with `cadre` and `superpowers`, and nothing it enables or names comes from colette-club except `elixir-phoenix-conventions`. No spec tracked in Cadre names `colette:writing-plans`.

**Architecture:** one PR per repo, in the Consumers table's order: colette-api, colette-app, rooms-app, admin-app, kinfield, cadre, colette-marketplace, cadre_marketplace. Each PR switches all of its repo's settings at once. Where the Skills table lists the two plugins (colette-api, colette-app, rooms-app, admin-app, colette-marketplace), a new test in its agent-skills test first pins the rule its `AGENTS.md` already states: each plugin row's plugin is enabled in `.claude/settings.json`, and its marketplace is declared there unless it is `claude-plugins-official` *(my call: a table switched without its settings, or settings without the marketplace, break every teammate's install)*. cadre's table lists neither plugin, so the switch can't turn its test red; cadre_marketplace has no agent-skills test, and adding one is beyond the spec. Machines follow the repos: before the first PR, David and the team drop their user-scope `@colette-club` copies; after each PR merges, each person runs that repo's commands once.

**Tech Stack:** JSON settings, Markdown, ExUnit (colette-api), Vitest (colette-app, rooms-app, admin-app), Minitest (colette-marketplace).

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`: Constraints, Anti-goals, Consumers, "Switching the team repos" and Increment 6. PR titles: `Cadre marketplace move (6/8): <repo> installs from the cadre marketplace`.

**Skills to load:** `superpowers:writing-skills`, `mattpocock-skills:writing-for-agents` (wins where they disagree), `engineering-review:engineering-principles`, `mattpocock-skills:tdd`; `cadre:pr-description` for each PR; in each repo, the rows of its own Skills table whose When fits (`elixir-phoenix-conventions:elixir-phoenix-conventions` for colette-api's `.exs` test). Since Task 0, `engineering-review` no longer loads in cadre_marketplace or admin-app sessions until their PRs merge: a subagent that can't load `engineering-review:engineering-principles` reads `plugins/engineering-review/skills/engineering-principles/SKILL.md` in this repo's checkout, the published 0.22.0 text.

## Global Constraints

- Edit nothing under colette-club's `plugins/`. colette-marketplace's settings and `AGENTS.md` change; its README waits for increments 7 and 8.
- Every repo's `enabledPlugins` holds these four, each `true`: `engineering-review@cadre`, `security-audit@cadre`, `cadre@cadre`, `superpowers@claude-plugins-official`. A `@colette-club` key for `engineering-review` or `security-audit` is replaced in place; the others are appended after the last key. kinfield and cadre gain `security-audit@cadre` too. A person's `claude plugin install engineering-review@cadre --scope project` writes every dependency it installs into the project's settings, so a file that already lists all four stays clean *(my call: the spec names only the first two)*.
- Every repo's `extraKnownMarketplaces` gains, after its last entry:

  ```json
  "cadre": {
    "source": {
      "source": "github",
      "repo": "djeusette/cadre_marketplace"
    },
    "autoUpdate": true
  }
  ```

  `autoUpdate` sits beside `source` (settings reference). colette-club's entry stays only where `elixir-phoenix-conventions@colette-club` stays: colette-api, kinfield and cadre.
- Every Skills-table install line for `engineering-review` or `security-audit` reads `claude plugin install <plugin>@cadre`.
- As Task 0 Step 3 says, nothing is registered in Cadre. English pages (colette-app) keeps its `colette:writing-plans` line, which increment 7 must settle with David. Every plan that names `engineering-review:pr-description` has shipped (inventory: `shipped-status-apps.md` and `shipped-status-cadre-marketplaces.md` in `/Users/djeusette/Library/Application Support/Claude/side-session-notes/local_d745618f-fcad-4c7a-a909-60c96791c594/`).
- Verify each switch in a throwaway `CLAUDE_CONFIG_DIR` under the scratchpad, never `~/.claude`. `claude` is `~/.local/bin/claude`.
- Commit subjects follow each repo's `git log`: Conventional Commits (`chore(claude):`, `docs(specs):`) in the team repos, `Cadre marketplace move: <what>` here. Only the PR title takes `Cadre marketplace move (6/8): …`. The PRs are not tracked in Cadre, so they carry no Cadre line.

## Review Focus

- A teammate who pulls a switched repo but hasn't run its commands: the `@cadre` plugins don't load there until they install them ("isn't installed here" in `/plugin`), and the `@colette-club` copy stops loading because the key is gone. Each PR's Before deploying and the team message say so.
- The commands run in a checkout that hasn't pulled the switch: the install writes the `@cadre` ids beside the `@colette-club` ones, both load and the file is dirty. The commands say to run them only where `.claude/settings.json` holds `engineering-review@cadre`.
- A machine with a user-scope `engineering-review@colette-club` beside a project's `@cadre` copy: both load. Task 0 drops the user-scope copies before the first PR.
- A person's project-scope install dirtying the committed settings: the four ids are listed, so it does not ("Verify a switch").
- A client older than 2.1.319: an update that adds a dependency leaves `engineering-review` disabled. The team message says to check `claude --version`.

---

### Task 0: David's settings and the team, before the first repo PR

- [x] **Step 1:** David said yes (2026-11-27). `claude plugin uninstall <id> --scope user` for `colette`, `engineering-review` and `security-audit` `@colette-club`: the three keys are gone, and `elixir-phoenix-conventions@colette-club` and `flutter-conventions-guide@colette-club` stay.
- [x] **Step 2:** The team message is `team-message.md` in the notes folder. David approved it and sends it himself.
- [x] **Step 3:** David chose: no Cadre project for cadre or the marketplaces, and only specs tracked in Cadre change, plus cadre's and the marketplaces' own. Nothing is registered.

### Per-person commands

Before the first PR, once per machine:

```bash
claude plugin uninstall colette@colette-club --scope user
claude plugin uninstall engineering-review@colette-club --scope user
claude plugin uninstall security-audit@colette-club --scope user
```

A command for a plugin that isn't installed at user scope fails with "not found in installed plugins", which is harmless.

After a repo's PR merges, in that repo's checkout, once `.claude/settings.json` there holds `engineering-review@cadre`:

```bash
claude plugin marketplace add djeusette/cadre_marketplace
claude plugin install engineering-review@cadre --scope project
claude plugin uninstall engineering-review@colette-club --scope project
claude plugin uninstall security-audit@colette-club --scope project
```

The first line is needed once per machine. The install brings `security-audit` and `cadre`, its dependencies, and `superpowers`, which `cadre` depends on. In cadre, `claude plugin uninstall colette@colette-club --scope project` runs before the other two uninstalls. Then run `/reload-plugins` in open sessions. Open branches and worktrees load neither marketplace's copy until `main` is merged into them.

### Verify a switch

From the PR's worktree, before the review:

```bash
export CLAUDE_CONFIG_DIR=<scratchpad>/verify-<repo> LANG=en_US.UTF-8
~/.local/bin/claude plugin marketplace add anthropics/claude-plugins-official
~/.local/bin/claude plugin marketplace add djeusette/cadre_marketplace
~/.local/bin/claude plugin install engineering-review@cadre --scope project
git diff --exit-code .claude/settings.json
~/.local/bin/claude plugin list
```

It passes when `git diff` prints nothing and the list shows exactly `engineering-review@cadre`, `security-audit@cadre`, `cadre@cadre` and `superpowers@claude-plugins-official`, each at project scope and enabled. `rg '@colette-club' .claude/settings.json` prints only `elixir-phoenix-conventions@colette-club`, or nothing.

### Per-repo steps

Each task below runs these, with the files, test and checks it names:

1. Worktree `~/Code/<repo>/.claude/worktrees/cadre-marketplace-move-6` on a new branch `cadre-marketplace-move-6` from `origin/main`, then `mix deps.get` or `bun install`.
2. Add the settings test. Run it: green on the unchanged files.
3. Change the task's Skills rows to `@cadre`. Run the test: red, naming `engineering-review@cadre`.
4. Switch `.claude/settings.json` as Global Constraints say. Run the test: green.
5. The task's own edits.
6. The repo's checks, all green. Commit.
7. "Verify a switch". Review ("Each PR's review"), push, open the PR.

The settings test asserts, for each Skills row whose install line is a `claude plugin install <plugin>@<marketplace>` command (colette-api's Elixir shown; each repo's language says the same):

```elixir
assert Map.get(enabled, id) == true,
       "#{id} is not in enabledPlugins in #{@settings_json}"

assert marketplace == "claude-plugins-official" or
         Map.has_key?(marketplaces, marketplace),
       "#{marketplace} is not in extraKnownMarketplaces in #{@settings_json}"
```

### Task 1: colette-api

**Files:** `test/colette/agent_skills_test.exs` (test `"enables every plugin row's plugin and declares its marketplace in .claude/settings.json"`, settings read with `JSON.decode!`), `AGENTS.md` (rows 30–31), `.claude/settings.json`, `docs/superpowers/specs/2026-11-09-live-recording-statuses-design.md` (line 4), `docs/superpowers/specs/2026-11-18-referral-code-tracking-design.md` (line 5 and the blank line above it).

- [x] Steps 1–4.
- [x] Step 5: drop the `colette:writing-plans` line from both specs.
- [x] Step 6: `mix test test/colette/agent_skills_test.exs`, then `mix precommit`.
- [x] Step 7.

### Task 2: colette-app

**Files:** `tests/agent-skills.test.ts` (the same test name), `AGENTS.md` (rows 23–24), `.claude/settings.json`, which lists `enabledPlugins` first, as the CLI writes it.

- [x] Steps 1–4.
- [x] No Step 5: the English pages spec isn't tracked in Cadre, so it stays as it is.
- [x] Step 6: `bun lint`, `bun typecheck`, `CI=true bun run test`. Biome ignores every path under `.claude/`, so in the worktree lint runs on the tracked top-level paths: `bunx @biomejs/biome lint $(git ls-tree --name-only HEAD | grep -v '^\.')`.
- [x] Step 7.

### Task 3: rooms-app

**Files:** `src/__tests__/agent-skills.test.ts`, `AGENTS.md` (rows 22–23), `.claude/settings.json` (gains `superpowers@claude-plugins-official` too).

- [x] Steps 1–4, 6 (`bun lint`, `bun typecheck`, `bun run test`), 7.

### Task 4: admin-app

**Files:** `tests/agent-skills.test.ts`, `AGENTS.md` (rows 20–21), `.claude/settings.json` (gains `superpowers@claude-plugins-official` too).

- [x] Steps 1–4, 6 (Task 2's lint, `bun typecheck`, `CI=true bun run test`), 7.

### Task 5: kinfield

**Files:** `.claude/settings.json` only: kinfield has no Skills table and no agent-skills test. colette-club stays.

- [x] Step 1 (the main checkout is 316 commits behind; the worktree starts from `origin/main`).
- [x] Step 4, without a test: `ruby -rjson -e 'JSON.parse(File.read(".claude/settings.json"))'` parses it.
- [x] Step 6: `mix precommit`.
- [x] Step 7. The review is the principles lens only: the diff holds no prose.

### Task 6: cadre

**Files:** `.claude/settings.json` (drops `colette@colette-club`; colette-club stays), `docs/superpowers/specs/2026-10-22-cadre-design.md`.

- [x] Step 1.
- [x] Step 4, without a test (`ruby -rjson` as Task 5).
- [x] Step 5: the cadre design spec, edited and not registered. Line 3 becomes `> Not tracked in Cadre, as David chose (2026-11-27). Plan each increment with \`superpowers:writing-plans\`, one at a time; its status line becomes \`- [x] PR #<n>\` when that PR opens.` Line 124 names `cadre:pr-description` "in the cadre marketplace", gives the review to `engineering-review`, and drops "The cadre skill keeps its own rule", which `cadre:pr-description` now holds. Line 812, history of increment 21, reads "`cadre:pr-description` (then `engineering-review:pr-description` in colette-marketplace)".
- [x] Step 6: `mix format --check-formatted && mix credo --strict && mix test && ruby script/test/all.rb`.
- [x] Step 7.

### Task 7: colette-marketplace

**Files:** `test/agent_skills_test.rb` (`test_enables_every_plugin_rows_plugin_and_declares_its_marketplace_in_settings`), `AGENTS.md` (rows 11–12, and the sentence "The colette-club plugins it enables are the published ones, not this checkout's."), `.claude/settings.json` (colette-club's entry goes).

- [x] Steps 1–4.
- [x] Step 5: the sentence becomes "`.claude/settings.json` enables `engineering-review` and `security-audit` from the cadre marketplace, not from this checkout's `plugins/`."
- [x] Step 6: `ruby test/agent_skills_test.rb`.
- [x] Step 7.

### Task 8: cadre_marketplace

**Files:** `.claude/settings.json`, `AGENTS.md` (Skills table), the spec's Increment 6 status line, this plan.

- [x] Step 4, without a test (`ruby -rjson` as Task 5).
- [x] Step 5: the Skills table gains three rows, after `superpowers:writing-skills`:

  ```markdown
  | `engineering-review:engineering-principles` | writing or reviewing any code: scripts, hooks, tests | `claude plugin install engineering-review@cadre` |
  | `security-audit:security-audit` | hooks, scripts that run commands, secrets or anything security-sensitive | `claude plugin install security-audit@cadre` |
  | `mattpocock-skills:tdd` | writing a test before the code | `claude plugin install mattpocock-skills@claude-plugins-official` |
  ```

  After "For a row naming a plugin skill, enable its plugin under `enabledPlugins` in `.claude/settings.json`.", the same paragraph gains: "`.claude/settings.json` enables the published `@cadre` plugins, not this checkout's `plugins/`."
- [x] Step 6: every check in `AGENTS.md` "Checks", and `ruby script/check_version_bumps.rb origin/main` prints `OK` (no plugin changes).
- [ ] Step 7.
- [ ] Step 8: once all eight PRs are open, Increment 6's status line becomes `- [x] PRs colette-club/colette-api#<n>, colette-club/colette-app#<n>, colette-club/rooms-app#<n>, colette-club/admin-app#<n>, djeusette/kinfield#<n>, djeusette/cadre#<n>, colette-club/colette-marketplace#<n>, #<n>`, committed on this branch and pushed. Append the increment's note to `move-progress.md` in `/Users/djeusette/Library/Application Support/Claude/side-session-notes/local_5986f0d0-b560-4215-a9f8-8216ee396103/`.

### Each PR's review

- **Round 1:** two subagents on the PR's whole diff: one `engineering-principles` review rule by rule, one `writing-for-agents` review where the diff holds prose. Fix every finding, Minors included.
- **Later rounds** review only `git diff <last-reviewed-sha>..HEAD`, with every earlier ruling passed as a standing decision. Stop when a round is clean on both.
- Record each round under "Reviews", by repo, as "<lens>: clean." or "<lens> (<n> Minor), fixed: <entry or file> says <what>."
- **The PR** is described to `cadre:pr-description`. "Before deploying" holds two items: the user-scope copies dropped on every machine, and the team told the repo's commands. "How it works" holds the commands. No Break checks table: no branch of code changes.

## Install, verified

In scratch `CLAUDE_CONFIG_DIR`s, 2026-11-27, Claude Code 2.1.331:

- `claude plugin install engineering-review@cadre --scope project` in a repo whose settings enable the four ids and declare the cadre marketplace installs engineering-review 0.22.0, security-audit `c1c8a8c1`, cadre 0.35.1 and superpowers 7.0.2 at project scope, and leaves the settings unchanged. With only `engineering-review@cadre`, `cadre@cadre` and superpowers listed, it appended `"security-audit@cadre": true`. It rewrites a file whose `extraKnownMarketplaces` comes before `enabledPlugins` with `enabledPlugins` first (colette-app).
- Without `claude plugin marketplace add djeusette/cadre_marketplace` first, the install fails ("not found in marketplace cadre"): the project's `extraKnownMarketplaces` is honoured only after the folder is trusted, which the CLI alone doesn't do.
- `claude plugin uninstall engineering-review@colette-club --scope project` after the switch removes the old copy and leaves the settings alone. `--scope user` removes the key from the user's settings. A plugin not installed at that scope fails harmlessly.
- A git worktree under `.claude/worktrees/` lists the main checkout's project installs as enabled.

## Reviews

- Plan: Fable (1 Critical, 7 Important, 11 Minor), fixed.
- colette-api: round 1 principles clean; writing (1 Important, 4 Minor), fixed: the commit body says `cadre@cadre` is engineering-review's dependency, the test's name and messages name `extraKnownMarketplaces` and `enabledPlugins`, the moduledoc says "each with its marketplace", the docs commit points to `cadre:cadre`. Round 2 principles clean; writing (1 Minor), fixed: the commit body names the exact install command. Round 3 clean on both.
- colette-app: round 1 clean on both.
- rooms-app, admin-app: round 1 principles clean; writing (1 Minor each), fixed: the commit body says superpowers is cadre's dependency. Round 2 writing clean.
- kinfield: round 1 principles clean.
- cadre: round 1 principles (2 Minor) and writing (1 Important, 1 Minor), fixed: line 124 drops the cadre skill's own rule and gives the review to `engineering-review`, line 812 says "then `engineering-review:pr-description`", the docs commit body names every edit.
- colette-marketplace: round 1 principles (1 Minor) and writing (1 Minor), fixed: `AGENTS.md` says `.claude/settings.json` enables the two plugins from the cadre marketplace.
- cadre_marketplace: round 1 principles (5 Minor) and writing (2 Important, 7 Minor), fixed: one commit per change; `AGENTS.md` says `.claude/settings.json` enables the published `@cadre` plugins; the plan says "holds" these four, the install's dependencies, the tests' real names, each repo's commit form, David's call once, and ticks the steps done.
