# Brainstorm a feature into milestones

You brainstorm the feature with the person through `superpowers:brainstorming`, and it ends as a feature spec: an end goal and the milestones that reach it. The cadre skill turns that spec into a project.

## Before you start

Check that `superpowers:brainstorming` is among your available skills. When it is missing, tell the person to install and enable the `superpowers` plugin from the `claude-plugins-official` marketplace, and stop.

## Run superpowers brainstorming

Invoke `superpowers:brainstorming` with the person's request, and follow it as written: its conversation, playback, visual companion, written design, builder check and approval gate. Invoke it from this file, not through a workflow that wraps it, so the project gets registered. The rules in this file add to it. Where they differ from it, they win:

- **Size.** A feature always gets a written spec, even when it fits in one milestone.
- **Ground to cover.** Add the repos it touches, which one must deploy first, and the apps that use what changes.
- **Recon.** Read the current repo's code without asking, to ground your questions and size the milestones, and say so in your next message. Ask before reading anything outside it; for a repo you can't read, mark its code-file count as your guess.
- **Skipping the questions.** When the person says to skip the questions, the brainstorm still ends with the spec: write it from what they said, mark every open point as your call, skip the builder check, and ask them once to approve the spec, with its milestones and your calls.
- **The written design** is the feature spec below.
- **After approval**, follow "The handoff" instead of invoking `superpowers:writing-plans`.

## What a milestone is

Each milestone is one increment of the feature. It:

- ships one feature as the smallest step that can be deployed and used: no unrelated fix or refactor, no code the feature doesn't use yet, nothing that could ship on its own first;
- deploys on its own: it works while the previous version still runs during the rollout, so no column the running version uses is dropped or renamed; what is unfinished stays out of users' reach; and a rollback loses no data;
- changes a contract other apps use, such as an API field or endpoint, an error, an event or webhook payload or a shared table, only in a backward-compatible way: add the new, move every consumer, and remove the old only once no deployed consumer uses it, installed mobile app versions included;
- names its consumers: every frontend and app that depends on what changes, whether each must change, and the deploy order, with the repo that must deploy first listed first;
- may rely on earlier milestones, never on a later one;
- moves the end goal forward: the milestones are the path to it, not slices cut from a finished design afterwards.

Prefer the thinnest slice someone can use end to end. Cut by layer (data, then the write path, then the API) only when no usable slice fits, and keep the unfinished part out of users' reach.

A request that fits in one milestone gets one milestone: never invent a split to make the work look incremental.

## Drafting the milestones

Draft the milestones while the design takes shape:

1. Read the code to estimate the code files each milestone touches. Tests and docs are not code files.
2. Size each one: aim for 10 code files, and prefer 20 code files or fewer. This is a preference, not a limit: a milestone above 20 says why it can't be smaller.
3. Challenge each milestone once, yourself: could it ship as two smaller ones that each deploy and give someone something to use? If so, split it. Don't ask the person this for each milestone.
4. Play the milestones back with the rest of the design, so the person sees and corrects the path, not only the end goal.

## The feature spec

Write it to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` in the current repo, with today's date. When that file exists, add `-2`, `-3`, … before `.md`, so an earlier spec is never overwritten.

Title it `# <Feature> — design`. After what superpowers' written design covers, it ends with these two sections, in this order:

```markdown
## End goal

<What exists when every increment has shipped, and why.>

## Increments

### Increment <i> — <the one thing it delivers>

- **Delivers:** <what someone can do once it is deployed>
- **Deployable alone:** <what stays hidden or behind a flag; how contracts other apps use stay compatible; what runs while the previous version is still deployed>
- **Consumers:** <the frontends and apps that must change, or "none"; what deploys first>
- **Code files:** <count> — <expected paths>
```

Increments are numbered from 1, and each one becomes a milestone in Cadre. They have no status line: Cadre shows where each one stands.

In the builder check, the builder plans increment 1 from the spec.

## The handoff

Commit nothing until the person approves the spec. Once they do, commit only the spec file, with `git add <path>` and `git commit -m "docs: <feature> design" -- <path>`, and never push: the person's other changes, staged or not, stay as they are.

Go back to step 2 of the cadre skill's "Create a project".
