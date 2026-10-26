# Brainstorm a feature into milestones

You find out with the person what they want and why, then write it as a feature spec: an end goal and the milestones that reach it. The cadre skill turns that spec into a project. Follow this file instead of any other brainstorming or planning workflow you have, so the project gets registered.

## The conversation

Your first message is one line saying they can skip the questions and have you propose the milestones, then one open question about a real moment, such as "What's the moment you find yourself wishing this existed?"

After that, each message ends with one question: a single sentence, with no list of example answers. Use plain language and their words. Get them describing first. Offer a short menu only when they are stuck. When they say "just guess", propose something concrete they can correct.

Ground to cover, never read out as a list:

- what the feature is, and why now;
- what success looks like, and who uses it;
- goals, non-goals and anti-goals: what would make it a failure even if it works;
- what exists today, and what they have tried;
- the repos it touches, which one must deploy first, and the apps that use what changes.

Read the current repo's code without asking, to ground your questions and size the milestones, and say so in your next message. Ask before reading anything outside it; for a repo you can't read, mark its code-file count as your guess.

Before you propose anything, think of several approaches privately and drop the weak ones, including any that fight what they told you about why. A choice you make yourself goes into the spec as your call, never as something they agreed to.

Play back as you go. Once you understand a part, such as who it serves, how one piece behaves or the milestones, describe it back in about 200–300 words. Mark what you are guessing, and end by asking what's wrong or missing. Then go on to the next part.

When the person says to skip the questions, write the spec from what they said: mark every open point as your call, skip the builder's read below, and ask them once to approve the spec, with its milestones and your calls.

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

Title it `# <Feature> — design`. Write it for a builder who plans from it without going back to the person. It covers:

- the why;
- goals, non-goals and anti-goals;
- constraints;
- the parts of the how the person decided, as they decided them;
- what's left to the builder.

It ends with these two sections, in this order:

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

Before you show the spec, read it as the builder who plans increment 1 without the person:

1. Settle what a sensible builder could settle, and mark it in the spec as your call.
2. Bring only what the person must decide, in one message, most important first.
3. Update the spec with their answers.

Then give the person the spec's path and the list of calls you made, and ask them to approve it. Commit nothing until the person approves. Then commit only the spec file, with `git add <path>` and `git commit -m "docs: <feature> design" -- <path>`, and never push: the person's other changes, staged or not, stay as they are.

Go back to step 2 of the cadre skill's "Create a project".
