# colette-club holds only conventions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** colette-club lists `elixir-phoenix-conventions` and `flutter-conventions-guide` only. `engineering-review`, `security-audit`, `plugins/engineering-review/` and the break-check spec are gone, `renames` maps both names to `null`, and the README points to the cadre marketplace for the rest.

**Architecture:** one PR in colette-marketplace. `renames` gains `"engineering-review": null` and `"security-audit": null` beside `"colette": null`: each machine drops those `@colette-club` keys from every scope's settings, and the installed copies stop loading. Every team repo installs both from the cadre marketplace since increment 6 (club-mobile included, colette-club/club-mobile#222).

**Tech Stack:** JSON, Markdown, Minitest.

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, Increment 8. PR title: `Cadre marketplace move (8/8): colette-club holds only conventions`.

**Skills to load:** `mattpocock-skills:writing-for-agents`, `engineering-review:engineering-principles`, `cadre:pr-description` for the PR.

## Global Constraints

- Increment 8's Before deploying is met: every increment 6 PR is merged, the team confirmed they ran the switch commands (David, 2026-11-27), increment 7 is merged, and the break-check spec's successor is on the cadre marketplace's `main` (#41).
- `renames` sits at the top level of `.claude-plugin/marketplace.json`, beside `plugins`. Edit the file as text, keeping its layout.
- Shipped specs and plans that name `engineering-review` stay: they are history. The break-check spec, `docs/superpowers/specs/2026-11-25-break-check-design.md`, is deleted, as the spec says.
- The conventions plugins don't change. `elixir-phoenix-conventions`' SKILL.md names "the `engineering-principles` skill of the `engineering-review` plugin, where that plugin is installed", which stays true.
- Commit subjects follow colette-marketplace's `git log` (Conventional Commits).

## Review Focus

- A machine still enabling `engineering-review@colette-club` or `security-audit@colette-club` at user or project scope: the next update drops the keys ("Verify", below). The team ran the switch commands, so the cadre copies are installed there.
- A repo's committed settings still enabling either `@colette-club`: none, after a scan of every `~/Code` repo's default branch.
- `.gitignore`'s `__pycache__/` and `plugins/*/evals/results/` lines served `engineering-review`'s Python scripts and evals. No tracked `.py` file or `evals/` folder is left, so both sections go *(my call: EP-I1)*.

---

### Task 1: colette-marketplace

**Files:**
- Delete: `plugins/engineering-review/`, `docs/superpowers/specs/2026-11-25-break-check-design.md`
- Modify: `.claude-plugin/marketplace.json`, `README.md`, `AGENTS.md`, `.gitignore`

- [x] **Step 1:** Worktree `~/Code/colette-marketplace/.claude/worktrees/cadre-marketplace-move-8` on `cadre-marketplace-move-8`, clean and at `origin/main`.
- [x] **Step 2:** `git rm -r -q plugins/engineering-review docs/superpowers/specs/2026-11-25-break-check-design.md`. In `marketplace.json`, drop the `engineering-review` and `security-audit` entries and add both names to `renames`, after `colette`.
- [x] **Step 3:** README: drop the `engineering-review` bullet; the cadre line becomes: "`cadre`, `engineering-review` and `security-audit` moved to their own marketplace, [djeusette/cadre_marketplace](https://github.com/djeusette/cadre_marketplace). `cadre` replaces the former `colette` plugin: `cadre:brainstorming` brainstorms a feature and `cadre:writing-plans` plans it." ("`cadre` replaces", not "It replaces", since the sentence before names three plugins.) AGENTS.md: the sentence "`.claude/settings.json` enables `engineering-review` and `security-audit` from the cadre marketplace, not from this checkout's `plugins/`." goes: with the checkout's copy gone it only restates the settings. `.gitignore`: drop the Python and Eval run output sections.
- [x] **Step 4:** `rg -n --hidden -g '!docs/**' -g '!.git' 'engineering-review|security-audit|break-check'` prints exactly eight lines: `.claude/settings.json`'s two `@cadre` keys, `AGENTS.md`'s two Skills rows, the README's cadre line, the two `renames` lines and `elixir-phoenix-conventions`' SKILL.md line. `~/.local/bin/claude plugin validate . --strict` passes. `ruby test/agent_skills_test.rb` is green.
- [x] **Step 5:** Commit: `chore: remove engineering-review and security-audit, now in the cadre marketplace`.
- [x] **Step 6:** Verify, review, push, PR: colette-club/colette-marketplace#51.
- [ ] **Step 7:** After the merge, David's main checkout keeps `~/Code/colette-marketplace/plugins/engineering-review/evals/results/` and `~/Code/colette-marketplace/plugins/engineering-review/scripts/__pycache__/`, untracked once `.gitignore` drops them. Ask David before deleting `~/Code/colette-marketplace/plugins/engineering-review/`.

### Task 2: cadre_marketplace

- [x] **Step 1:** Once the PR is open, Increment 8's status line becomes `- [x] PR colette-club/colette-marketplace#<n>`, committed with this plan on `claude/cadre-marketplace-move-8`. Every check in `AGENTS.md` "Checks" and `ruby script/check_version_bumps.rb origin/main` pass. Push and open its PR.
- [ ] **Step 2:** Append the increment's note to `/Users/djeusette/Library/Application Support/Claude/side-session-notes/local_5986f0d0-b560-4215-a9f8-8216ee396103/move-progress.md`.

### Verify

In a scratch `CLAUDE_CONFIG_DIR`, with a clone made by `git clone https://github.com/colette-club/colette-marketplace <clone>` (its `main`):

1. `claude plugin marketplace add <clone>`, `claude plugin marketplace add djeusette/cadre_marketplace`, `claude plugin install engineering-review@colette-club --scope user`, `claude plugin install engineering-review@cadre --scope user` (each install brings its dependencies: `security-audit`, plus `cadre` for `@cadre`).
2. `git -C <clone> fetch <worktree> cadre-marketplace-move-8`, check out `FETCH_HEAD`, `claude plugin marketplace update colette-club`.
3. `claude plugin list` twice: the first applies the rename and still prints `✔ enabled`.

It passes when `enabledPlugins` in `$CLAUDE_CONFIG_DIR/settings.json` held `engineering-review@colette-club` and `security-audit@colette-club` before step 2 and holds neither after step 3, the second list shows `engineering-review@colette-club` and `security-audit@colette-club` `✘ disabled`, and `engineering-review@cadre`, `security-audit@cadre` and `cadre@cadre` stay `true` and `✔ enabled`.

Done 2026-11-27, Claude Code 2.1.331: it passed. Two same-named plugins from two marketplaces installed side by side in one config.

### The PR's review

Round 1 on the whole diff, excluding the deleted `plugins/engineering-review/`: one `engineering-principles` review rule by rule and one `writing-for-agents` review. Later rounds review only the delta, with earlier rulings standing. Stop when a round is clean on both. The PR is described to `cadre:pr-description`; nothing is left before deploying, so it has no Before deploying section.

## Reviews

- Plan: Fable (4 Important, 5 Minor), fixed: Steps 1–5 ticked, Step 4's `rg` count exact, AGENTS.md's restating sentence cut, Step 7's cleanup, Verify checks the `@cadre` copies survive.
- Round 1 principles (1 Minor) and writing (3 Minor), fixed: the commit body wraps at 72 and names the move, Verify says which installs bring which dependencies and which two plugins end disabled, Step 7 gives full paths. Round 2 principles clean; writing (1 Minor), fixed: Step 7's paths all start at `~/Code/colette-marketplace`. Round 3 clean on both.
