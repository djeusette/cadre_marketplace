# The colette plugin goes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** colette-club no longer lists `colette`. Its entry and `plugins/colette/` are gone, a `renames` entry maps `colette` to `null`, and the README stops describing it. The team brainstorms and plans through `cadre`, or with plain superpowers.

**Architecture:** one PR in colette-marketplace. `renames: {"colette": null}` drops the `colette@colette-club` key from every scope's settings on each machine; the marketplace reference says a session's `/plugin` then shows `Removed from the "colette-club" marketplace`. Without `forceRemoveDeletedPlugins` the installed copy stays on disk but no longer loads, which is all the spec asks. No test reads colette: `test/agent_skills_test.rb` is a regression check.

**Tech Stack:** JSON, Markdown, Minitest.

**Spec:** `docs/superpowers/specs/2026-11-26-cadre-marketplace-move-design.md`, Increment 7. PR title: `Cadre marketplace move (7/8): the colette plugin goes`.

**Skills to load:** `mattpocock-skills:writing-for-agents`, `engineering-review:engineering-principles`, `cadre:pr-description` for the PR.

## Global Constraints

- Edit nothing under colette-club's `plugins/` except deleting `plugins/colette/`. `engineering-review` there stays frozen until increment 8.
- `renames` sits at the top level of `.claude-plugin/marketplace.json`, beside `plugins` (marketplace reference): `"renames": { "colette": null }`.
- Shipped docs that name `colette` stay: they are history. So does the break-check spec, which increment 8 deletes. David chose (2026-11-27) to leave colette-app's English pages spec as it is. `AGENTS.md` names nothing of colette, so the spec's "AGENTS.md drop it" needs no edit.
- Before deploying: every PR of increment 6 merged (done), and every person has run the switch commands.
- Commit subjects follow colette-marketplace's `git log` (Conventional Commits).

## Review Focus

- A machine where `colette@colette-club` is still enabled at user scope: the next marketplace update drops the key ("Verify", below). The dependencies colette installed (`engineering-review` and `security-audit` `@colette-club`) stay enabled; increment 6's switch commands uninstall them at user scope.
- A project's committed settings that still enable `colette@colette-club`: only cadre did, and its increment 6 PR dropped it. None of the team repos at `origin/main` commits it.
- `allowCrossMarketplaceDependenciesOn: ["claude-plugins-official"]` existed for colette's `superpowers` dependency. No plugin left declares a dependency on another marketplace (`engineering-review` depends on `security-audit`, by bare name), so the key goes with it *(my call: EP-I1)*.

---

### Task 1: colette-marketplace

**Files:**
- Delete: `plugins/colette/`
- Modify: `.claude-plugin/marketplace.json` (the `colette` entry, `allowCrossMarketplaceDependenciesOn`, `renames`), `README.md` (the colette bullet; the cadre line says cadre replaces it), `.gitignore` (`plugins/colette/evals/*/deps/`)

- [x] **Step 1:** Worktree `~/Code/colette-marketplace/.claude/worktrees/cadre-marketplace-move-7` on `cadre-marketplace-move-7`, clean and at `origin/main`.
- [x] **Step 2:** `git rm -r -q plugins/colette`. Drop the `colette` entry and `allowCrossMarketplaceDependenciesOn` by text edits, keeping the file's layout, and add `renames` after `plugins`. Drop the README's colette bullet; its cadre line gains "It replaces the former `colette` plugin: `cadre:brainstorming` brainstorms a feature and `cadre:writing-plans` plans it." Drop the `.gitignore` line.
- [x] **Step 3:** `rg -n --hidden -g '!docs/**' -g '!.git' 'colette:|plugins/colette|"colette"'` prints exactly `.claude-plugin/marketplace.json: "colette": null`. `~/.local/bin/claude plugin validate . --strict` passes. `ruby test/agent_skills_test.rb` is green.
- [x] **Step 4:** Commit: `chore: remove the colette plugin, replaced by cadre`.
- [x] **Step 5:** Verify, review, push, PR: colette-club/colette-marketplace#50.
- [ ] **Step 6:** After the merge, David's main checkout keeps ten ignored `plugins/colette/evals/*/deps/` directories, untracked once `.gitignore` drops them. Ask David before deleting `~/Code/colette-marketplace/plugins/colette/`.

### Task 2: cadre_marketplace

- [x] **Step 1:** Once the PR is open, Increment 7's status line becomes `- [x] PR colette-club/colette-marketplace#<n>`, committed with this plan on `claude/cadre-marketplace-move-7`. Every check in `AGENTS.md` "Checks" and `ruby script/check_version_bumps.rb origin/main` pass. Push it and open its PR.
- [ ] **Step 2:** Append the increment's note to `/Users/djeusette/Library/Application Support/Claude/side-session-notes/local_5986f0d0-b560-4215-a9f8-8216ee396103/move-progress.md`.

### Verify

In a scratch `CLAUDE_CONFIG_DIR`, with a clone made by `git clone https://github.com/colette-club/colette-marketplace <clone>` (its `main`):

1. `claude plugin marketplace add anthropics/claude-plugins-official`, `claude plugin marketplace add <clone>`, `claude plugin install colette@colette-club --scope user`.
2. `git -C <clone> fetch <worktree> cadre-marketplace-move-7` and check out `FETCH_HEAD`; `claude plugin marketplace update colette-club`.
3. `claude plugin list` twice: the first applies the rename and still prints `✔ enabled`.

It passes when `enabledPlugins` in `$CLAUDE_CONFIG_DIR/settings.json` held `colette@colette-club: true` before step 2 and lacks it after step 3, the second list shows colette `✘ disabled`, and `engineering-review@colette-club` and `security-audit@colette-club` stay enabled. No CLI command prints the removal notice; the marketplace reference says it shows in a session's `/plugin`, which a scratch config can't open (not logged in).

### The PR's review

Round 1 on the whole diff: one `engineering-principles` review rule by rule and one `writing-for-agents` review. Later rounds review only the delta, with earlier rulings standing. Stop when a round is clean on both. The PR is described to `cadre:pr-description`. The PR's Before deploying holds the Global Constraints item still open.

## Install, verified

2026-11-27, Claude Code 2.1.331, scratch config: after `marketplace update`, `claude plugin update colette@colette-club` failed with `Plugin "colette" not found`, `colette@colette-club` left the user settings, and the list showed it `✘ disabled`; `engineering-review@colette-club` and `security-audit@colette-club` stayed enabled. Fable's run found the same with `claude plugin list` twice.

## Reviews

- Plan: Fable (1 Critical, 2 Important, 8 Minor), fixed: Verify's steps and pass criterion, Step 3's `rg` reads hidden paths, the post-merge cleanup, AGENTS.md's coverage, the skills list. Round 1 principles (1 Minor) and writing (3 Minor), fixed: the `/plugin` notice is attributed to the marketplace reference, the dependencies' uninstall names increment 6's switch commands, the clone comes from GitHub, and Before deploying has one source. Round 2 principles clean; writing (1 Minor), fixed: "The PR's Before deploying". Round 3 clean on both.
