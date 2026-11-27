# A repo's Skills table

A repo names the skills its work needs in a `## Skills` table in its root `AGENTS.md`: one row per skill, with when it applies and how to get it. Read it whenever you plan, as the `cadre:writing-plans` skill says, and draft one when the person asks ("Write this repo's Skills table with the cadre skill.").

## Read the table

Run, from the repo:

```bash
ruby <skills.md's folder>/skills_table.rb "$(git rev-parse --show-toplevel)"
```

- When the script exits non-zero, show the person its output and stop.
- When `table` is false, go to "No Skills table".
- Otherwise, go on to "Check each row".

## Check each row

Check every row before answering. A row stops the work when it has `problems`, or when it isn't `committed` (it names a plugin skill) and its Skill is not among the skills this session can load: a review or a plan without that skill would miss it. When any row stops the work, name every such row to the person in one answer, and stop:

- a row with `problems`: what the script names, and that the fix is the layout in "The table's shape";
- a plugin this session can't load: its Install command. The plugin loads in a new session, after it is installed and enabled in `.claude/settings.json`.

Whether or not a row stops the work, also tell the person:

- with `unlisted` folders: no row lists them;
- with `imports_agents_md` false: `CLAUDE.md` lacks the line `@AGENTS.md`, so Claude Code doesn't read the table on its own.

With no row stopping the work, go on to "Load what the work needs".

## Load what the work needs

Load every row whose When fits the work, before planning.

## No Skills table

Tell the person the repo has no Skills table, and ask whether to draft it now or go on without it.

- Draft it now: follow "Draft a Skills table".
- Going on without it is always allowed: go on to "Load what the work needs", loading and naming the skills the session has that fit the work.

## Draft a Skills table

1. Read the repo's stack: its manifests (`mix.exs`, `package.json`, `pubspec.yaml`, `Gemfile`, `pyproject.toml`, …), the file types it holds, and its tests and the services it calls.
2. For each kind of work the repo has, list every skill the session can load for that kind of work, from the person's user and project settings and their plugins alike: a frontend app gets every frontend skill (design, accessibility, UI copy and design-to-code included), a repo with a database gets the skills for its queries and migrations, and every repo gets the skills for any code (engineering principles, security, writing tests first). The list is exhaustive: the person trims it, so a skill that might fit is a row. Leave out only a skill that is neither a plugin nor installable from a public source, and say which you left out: a teammate couldn't get it.
3. Show the person the proposed rows: Skill, When, and how to get it (the plugin, or committed from its source). Ask them to confirm or change them. The draft writes nothing until the person confirms.
4. Once they confirm:
   - write the `## Skills` section as "The table's shape" says, with the line `Load each skill whose When fits the work before starting it, and name them in every subagent brief.` after the table;
   - commit each skill that isn't a plugin: `npx skills add <owner/repo> -s <name> -a claude-code -y` writes it into `.claude/skills/`; move that folder to `.agents/skills/<name>`, then `ln -s ../../.agents/skills/<name> .claude/skills/<name>`;
   - enable each plugin in `.claude/settings.json` under `enabledPlugins`, and add its marketplace under `extraKnownMarketplaces` when it isn't `claude-plugins-official`;
   - add the line `@AGENTS.md` to `CLAUDE.md`, creating it when the repo has none.
5. Read the table again, fixing what it names, until the script reports no `problems`, then name any `unlisted` folders to the person and show them the diff.
6. When the person says, commit only those files: while planning a milestone, on the milestone's branch, so the table ships with its pull request; otherwise on the branch the person names, asking which when they name none. Then, while planning, go on to "Check each row".

## The table's shape

Under the heading `## Skills`, before the next `## ` heading:

```markdown
| Skill | When | Install |
| --- | --- | --- |
| `<skill>` | <when it applies> | committed in `.agents/skills/` |
| `<plugin>:<skill>` | <when it applies> | `claude plugin install <plugin>@<marketplace>` |
```

- Skill is the name a session loads it by: a plugin's skill is `<plugin>:<skill>`.
- When names the work in plain words (`Ash resources or domains`), not a file glob (`lib/**/*.ex`).
- Install is `committed in .agents/skills/` for a skill in `.agents/skills/<name>/SKILL.md`, linked from `.claude/skills/<name>` to `../../.agents/skills/<name>`; otherwise `claude plugin install <plugin>@<marketplace>`.
