---
name: writing-plans
description: Cadre planning, which plans one pull request at a time for a Cadre milestone or for requirements. Use only when the person names it ("cadre:writing-plans", "cadre's planning"), or when the cadre skill calls it from "Start a milestone".
---

# Cadre writing plans

You plan one pull request at a time through `superpowers:writing-plans`: one repo's part of a Cadre milestone, or requirements given with no spec. Later milestones are planned once this one has shipped, with what it taught.

## Before you start

1. Check that `superpowers:writing-plans` is among your available skills. When it is missing, tell the person to install and enable the `superpowers` plugin from the `claude-plugins-official` marketplace, and stop.
2. Find what to plan, as "What to plan" says, and tell the person what you chose and why.
3. For "A Cadre milestone" and "A spec not tracked in Cadre", run only "Before you start", "Install or update the CLI" and "Sign in" in [the cadre skill](../cadre/SKILL.md), then come back here. When one of those sections says to stop, the planning stops too. This step is done once "Sign in" ends with the person signed in. The cadre skill's rules for a command's flags and for a refusal no file names, at the end of its "What to read next", hold for the rest of this run.

## What to plan

Take the first case that fits the request, then follow the section named for the case:

- **Handed over:** step 5 of "Start a milestone" in [milestone.md](../cadre/milestone.md) handed you its spec copy's path. Its steps 1 to 4 and the cadre skill's checks are done: go to step 3 of "A Cadre milestone".
- **A Cadre milestone:** the request names a milestone, `<slug>/<n>`, a Cadre project, or a spec whose line under its title says it is tracked in Cadre. A tracked spec's status lines, when it has some, are ignored: Cadre shows where each milestone stands.
- **A spec not tracked in Cadre:** the request names a spec without that line.
- **Requirements with no spec:** the request describes a feature or a change, not only a spec or a project by name.

When none fits, ask the person what to plan: a milestone, a spec or requirements.

## A Cadre milestone

1. Find the milestone `<slug>/<n>`: the one the request names. A spec tracked in Cadre as `<slug>` names only its project: its increment `<i>` is milestone `<slug>/<i>`. When the request gives no number, take the milestone whose `current` is true in `cadre status <slug> --json`, and say so; when none is, ask the person which.
2. Run only steps 1 to 4 of "Start a milestone" in [milestone.md](../cadre/milestone.md) for `<slug>/<n>`, then come back here. When one of those steps says to stop, the planning stops too. This step is done when you hold the spec copy's path, this repo's part and, for one app's pull request, its app, on the milestone's branch.
3. Run `cadre status <slug> --json`. Its `milestones` lists the project's milestones in order, not by number. When an entry before `<n>`'s has a `state` that is neither `can_deploy` nor `deployed`, its pull requests aren't all merged yet: name it to the person and ask whether to plan anyway.
4. Read the code as it is now, without asking. Check that this repo's part still ships as one pull request, as "One pull request" says, and estimate its code files. When the earlier milestones changed the picture, propose the change to the milestone's spec. Once the person approves it, update it as "Update a milestone's spec" in [project.md](../cadre/project.md) says, then pull and commit the spec copy again, as steps 1 and 4 of "Start a milestone" do.
5. Plan as "Run superpowers writing-plans" says, with the spec copy's path and only this repo's part of `<slug>/<n>`, or the app "Start a milestone" chose. The plan's header says it is tracked in Cadre, on the line under its title, so whoever executes it uses the `cadre:cadre` skill:

   ```markdown
   > **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n>`.
   ```

   For one app's plan, the line ends with ` <app>`: `Cadre: <slug>/<n> <app>`.

## A spec not tracked in Cadre

Register it first: follow "Create a project" in [project.md](../cadre/project.md) from step 1, with that spec. It brainstorms the spec's End goal and Increments through `cadre:brainstorming` when the spec lacks either. Once `cadre project create` has registered the project, plan milestone `<slug>/1` as "A Cadre milestone" says, from its step 2.

## One pull request

A plan is one pull request that ships one milestone: one feature, the smallest step that can be deployed and used on its own, and its consumers named, as "What a milestone is" in [the brainstorming skill](../brainstorming/SKILL.md) defines them. Read only that section there. Its code files are counted without tests and docs: aim for 10, and prefer 20 or fewer.

## Run superpowers writing-plans

1. Read the repo's Skills table, check its rows and load the skills the work calls for, as [skills.md](../cadre/skills.md) says.
2. Invoke `superpowers:writing-plans` with the spec copy's path or the requirements, and these rules on top. Where they differ from it, they win:
   - **One plan, one pull request.** Plan only the part this skill chose, as one plan and one pull request: the spec-coverage check covers that part alone.
   - **Size.** When the plan's file structure holds more than 20 code files, counted as "One pull request" says, the plan says why it can't be smaller. When it could be smaller, stop before writing the plan, and propose the split of a milestone to the person, as "Change a project" in [project.md](../cadre/project.md) adds a milestone.
   - **Skills per task.** Each task names the skills it needs (from the table when the repo has one), since a subagent executing it loads only those.
   - **The final review.** When the final review runs in rounds, each round fixes what it finds and the next reviews the fixes. The first round reviews the whole branch; each later round reviews only `git diff <last-reviewed-sha>..HEAD`, and its brief lists every earlier ruling as a standing decision. Each round records the commit it reviewed up to and its rulings under the plan's final review task, where the next round reads them. The review ends when a round is clean.
   - **The pull request task.** The plan ends with a pull request task, which names `cadre:pr-description` among the skills it loads: it holds the rules for the title, the `Cadre:` line and the `## Before deploying` section. It pushes the branch and opens the pull request, never a local merge.
3. Execute the plan as `superpowers:writing-plans` offers.
