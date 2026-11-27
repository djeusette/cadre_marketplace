---
name: writing-plans
description: Cadre planning, which plans one pull request at a time for a Cadre milestone or for requirements. Use only when the person names it ("cadre:writing-plans", "cadre's planning"), or when the cadre skill calls it from "Start a milestone".
---

# Cadre writing plans

You plan one pull request at a time through `superpowers:writing-plans`: one repo's part of a Cadre milestone, or requirements given with no spec. Later milestones are planned once this one has shipped, with what it taught.

## Before you start

1. Check that `superpowers:writing-plans` is among your available skills. When it is missing, tell the person to install and enable the `superpowers` plugin from the `claude-plugins-official` marketplace, and stop.
2. Find what to plan, as "What to plan" says. Except when handed over, tell the person what you chose and why.
3. For "A Cadre milestone" and "A spec not tracked in Cadre", run only "Before you start", "Install or update the CLI" and "Sign in" in [the cadre skill](../cadre/SKILL.md), then come back here. When one of those sections says to stop, the planning stops too. This step is done once "Sign in" ends with the person signed in. The cadre skill's rules for a command's flags and for a refusal no file names, at the end of its "What to read next", hold for the rest of this run.
4. Follow the section named for the case; when handed over, go to step 3 of "A Cadre milestone".

## What to plan

Take the first case that fits the request:

- **Handed over:** step 5 of "Start a milestone" in [milestone.md](../cadre/milestone.md) handed you `<slug>/<n>`, the spec copy's path, this repo's part and, for one app's pull request, its app. Steps 1 to 4 of "Start a milestone" and the cadre skill's checks are done.
- **A Cadre milestone:** the request names a milestone, `<slug>/<n>`, a Cadre project, or a spec whose line under its title says it is tracked in Cadre. A tracked spec's status lines, when it has some, are ignored: Cadre shows where each milestone stands.
- **A spec not tracked in Cadre:** the request names a spec without that line.
- **Requirements with no spec:** the request describes a feature or a change, not only a spec or a project by name.

When none fits, ask the person what to plan: a milestone, a spec or requirements.

## A Cadre milestone

1. Find the milestone `<slug>/<n>`: the one the request names. A spec tracked in Cadre as `<slug>` names only its project: its increment `<i>` is milestone `<slug>/<i>`. When the request gives no number, take the milestone whose `current` is true in `cadre status <slug> --json`, and say so; when none is, ask the person which.
2. Run only steps 1 to 4 of "Start a milestone" in [milestone.md](../cadre/milestone.md) for `<slug>/<n>`, then come back here. When one of those steps says to stop, the planning stops too. This step is done when you hold the spec copy's path, this repo's part and, for one app's pull request, its app, on the milestone's branch.
3. Run `cadre status <slug> --json`. Its `milestones` lists the project's milestones in order, not by number. When an entry before `<n>`'s has a step whose `repo` is this repo and whose `pull_requests` hold none with `status` `merged` or `deployed`, that milestone's work here isn't merged yet, so this branch lacks it: name it to the person and ask whether to plan anyway.
4. Read this repo's code as it is now, without asking, and estimate its part's code files, counted as "One pull request" says. When the part no longer ships as one pull request, propose a split to the person; when the earlier milestones changed the picture, propose the change to the milestone's spec. Once the person approves, land it: for a split, add the new milestone right after `<slug>/<n>` as "Change a project" in [project.md](../cadre/project.md) says, and narrow this milestone's spec to what stays in it; for a spec change, apply it. Make either change through "Update a milestone's spec" there, then run only steps 1, 2 and 4 of "Start a milestone" again and come back here. When one of them says to stop, the planning stops too. When the person declines a split, plan the part as it is: the plan says the person kept it whole. This step is done when you have told the person the estimate and what you proposed is settled.
5. Plan as "Run superpowers writing-plans" says, with the spec copy's path and only this repo's part of `<slug>/<n>`, or the app "Start a milestone" chose. The plan's header says it is tracked in Cadre, on the line under its title, so whoever executes it uses the `cadre:cadre` skill:

   ```markdown
   > **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n>`.
   ```

   For one app's plan, the line ends with ` <app>`: `Cadre: <slug>/<n> <app>`.

## A spec not tracked in Cadre

Register it first: follow "Create a project" in [project.md](../cadre/project.md) from step 1, with that spec. It brainstorms the spec's End goal and Increments through `cadre:brainstorming` when the spec lacks either. Once `cadre project create` has registered the project, plan milestone `<slug>/1` as "A Cadre milestone" says, from its step 2.

## Requirements with no spec

Read this repo's code without asking, then decide whether the requirements ship as one pull request, as "One pull request" says.

- **One pull request:** tell the person the work is one pull request, and why. Plan it as "Run superpowers writing-plans" says, with the requirements and no spec file. Cadre doesn't track it, so the plan has no tracking line and its pull request no `Cadre:` line.
- **More than one,** or when the size rule in "Run superpowers writing-plans" stops the plan: load `cadre:brainstorming` and brainstorm the feature from the requirements, as it says. Once "Create a project" has registered the project, come back here and plan milestone `<slug>/1` as "A Cadre milestone" says, from its step 2.

## One pull request

A plan is one pull request that ships one increment: one feature, the smallest step that can be deployed and used on its own, and its consumers named, as "What a milestone is" in [the brainstorming skill](../brainstorming/SKILL.md) defines a milestone. Read only that section there. Its code files are counted without tests and docs: aim for 10, and prefer 20 or fewer.

## Run superpowers writing-plans

1. Read the repo's Skills table, check its rows and load the skills the work calls for, as [skills.md](../cadre/skills.md) says.
2. Invoke `superpowers:writing-plans` with the spec copy's path or the requirements, and these rules on top. Where they differ from it, they win:
   - **One plan, one pull request.** Plan only the given part (this repo's part of the milestone, or its one app, or the requirements) as one plan and one pull request: the spec-coverage check covers that part alone.
   - **Size.** When the plan's file structure holds more than 20 code files, counted as "One pull request" says, the plan says why it can't be smaller. When it could be smaller and the person hasn't kept it whole at step 4, stop before writing the plan: propose a milestone's split as step 4 of "A Cadre milestone" says, then plan again from step 5; take requirements on to `cadre:brainstorming`, as "Requirements with no spec" says.
   - **Skills per task.** Each task names the skills it needs (from the table when the repo has one), since a subagent executing it loads only those.
   - **The final review.** Before the pull request task, the plan has a final review task. Its first round reviews the whole branch; each later round reviews only `git diff <last-reviewed-sha>..HEAD`, and its brief lists every earlier ruling as a standing decision. Each round fixes what it finds and records, in that task, the commit it reviewed up to and its rulings. The review ends when a round is clean.
   - **The pull request task.** The plan ends with a pull request task, which names `cadre:pr-description` among the skills it loads: it holds the rules for the title, the `Cadre:` line and the `## Before deploying` section. It pushes the branch and opens the pull request, never a local merge.
3. Execute the plan as `superpowers:writing-plans` offers.
