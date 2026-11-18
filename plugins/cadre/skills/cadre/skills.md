# A repo's Skills table

A repo names the skills its work needs in a `## Skills` table in its root `AGENTS.md`: one row per skill, with when it applies and how to get it. Read it whenever you start a milestone, as [milestone.md](milestone.md) says, and draft one when the person asks ("Write this repo's Skills table with the cadre skill.").

## Read the table

Run, from the repo:

```bash
ruby <this skill's folder>/skills_table.rb <repo root>
```

`<repo root>` is what `git rev-parse --show-toplevel` prints. It prints JSON: `table` (whether there is one), `rows` (each with `skill`, `when`, `install`, `committed` and `problems`), `unlisted` (committed folders no row names) and `imports_agents_md`. When `table` is false, go to "No Skills table".

## Check each row

- A row with `problems`: tell the person what the script names, and that the fix is the layout in "The table's shape". Then stop: a review or a plan on a broken row would miss that skill.
- A row that isn't `committed` names a plugin skill. When its Skill is not among the skills this session can load, stop and give the person its Install command. The plugin loads in a new session, after it is installed and enabled in `.claude/settings.json`.
- `unlisted`: tell the person no row lists those folders, and go on.
- `imports_agents_md` false: tell the person `CLAUDE.md` lacks the line `@AGENTS.md`, so Claude Code doesn't read the table on its own, and go on.

## Load what the work needs

Load every row whose When fits the milestone's work, before planning. Then name, in each task of the plan, the skills that task needs: execution runs each task in a subagent, which loads only the skills its brief names.

## No Skills table

Tell the person the repo has no Skills table, and ask whether to draft it now or go on without it. Going on without it is always allowed: then plan as you would have, naming in each task the skills the session has that fit it.

## Draft a Skills table

1. Read the repo's stack: its manifests (`mix.exs`, `package.json`, `pubspec.yaml`, `Gemfile`, `pyproject.toml`, …), the file types it holds, and its tests and the services it calls.
2. For each kind of work the repo has, list every skill the session can load for that kind of work, from the person's user and project settings and their plugins alike: a frontend app gets every frontend skill (design, accessibility, UI copy and design-to-code included), a repo with a database gets the skills for its queries and migrations, and every repo gets the skills for any code (engineering principles, security, writing tests first). The list is exhaustive: the person trims it, so a skill that might fit is a row. Leave out only a skill that is neither a plugin nor installable from a public source, and say which you left out: a teammate couldn't get it.
3. Show the person the proposed rows: Skill, When, and how to get it (the plugin, or committed from its source). Ask them to confirm or change them. The draft writes nothing until the person confirms.
4. Once they confirm:
   - write the `## Skills` section as "The table's shape" says, with the line `Load each skill whose When fits the work before starting it, and name them in every subagent brief.` under it;
   - commit each skill that isn't a plugin: `npx skills add <owner/repo> -s <name> -a claude-code -y` writes it into `.claude/skills/`; move that folder to `.agents/skills/<name>`, then `ln -s ../../.agents/skills/<name> .claude/skills/<name>`;
   - enable each plugin in `.claude/settings.json` under `enabledPlugins`, and add its marketplace under `extraKnownMarketplaces` when it isn't `claude-plugins-official`;
   - add the line `@AGENTS.md` to `CLAUDE.md`, creating it when the repo has none.
5. Read the table again until the script reports no `problems` and no `unlisted`, then show the person the diff. Commit when the person says.

## The table's shape

Under the heading `## Skills`, before the next `## ` heading:

```markdown
| Skill | When | Install |
| --- | --- | --- |
| `<skill>` | <when it applies> | committed in `.agents/skills/` |
| `<plugin>:<skill>` | <when it applies> | `claude plugin install <plugin>@<marketplace>` |
```

- Skill is the name a session loads it by: a plugin's skill is `<plugin>:<skill>`.
- When is plain words, not a glob: "Ash resources" can't be one.
- Install is `committed in .agents/skills/` for a skill in `.agents/skills/<name>/SKILL.md`, linked from `.claude/skills/<name>` to `../../.agents/skills/<name>`; otherwise `claude plugin install <plugin>@<marketplace>`.
