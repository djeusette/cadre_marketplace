---
name: cadre
description: Cadre CLI workflows. Use when the person asks to create, change or drop a project or its milestones in Cadre, read or update a milestone's spec, start a milestone ("start milestone <project>/<n>"), link a pull request to a milestone, connect a repo to where it deploys or ask where it does, connect a mobile app to its stores, deploy a repo that runs on Fly or Vercel, tick a Before deploying item, implement a spec or plan that says it is tracked in Cadre, or sign in to Cadre.
---

# Cadre

Cadre shows where every milestone of a feature stands, on every repo, in deploy order. You register a project there from the feature's spec with the `cadre` CLI: one milestone per increment of the spec, each with the repos it touches, its own spec and a link to its designs. When the feature has no spec yet, you brainstorm it with the person first.

## Before you start

Run `gh auth status`. When it fails, tell the person to run `gh auth login`, and stop. The CLI is downloaded with `gh`.

## Install or update the CLI

Run `cadre version`.

- When the command is missing, run:

  ```bash
  mkdir -p ~/.local/bin
  gh release download -R djeusette/cadre_cli --pattern "cadre_$(uname -s)_$(uname -m).tar.gz" -O - | tar -xz -C ~/.local/bin cadre
  ```

  Then run `cadre version` again. When the command is still missing, `~/.local/bin` is not on the person's `PATH`: tell them to add it, and stop.
- When it reports a version below `0.19.0`, run `cadre upgrade`. It replaces that `cadre` with the latest release and prints `Upgraded cadre from <old> to <new>.` When it fails, tell the person what it printed, and stop.

## Sign in

Run `cadre whoami --json`. It succeeds when the exit code is 0 and the JSON holds an `email`.

- `Not signed in. Run cadre login --url <url>.`:
  1. Ask the person for their Cadre URL, the address they open Cadre at in their browser, such as `https://cadre.example.com`. The URL comes from the person alone.
  2. Run `cadre login --url <url>` with it, in the background (Bash `run_in_background`) or with a `timeout` of 600000 ms. It waits up to 10 minutes for the person to click **Allow**, but the Bash tool stops a command after 2 minutes by default and shows no output until the command exits.
  3. Read its first two output lines, `Opening <uri> in your browser.` and `Check that the page shows this code: <code>`, and tell the person the URL and the code: they check that the page shows that code, then click **Allow**.
  4. Wait for the command to exit and read `Signed in as <email>.`
- `Your key for <url> is no longer valid. Run cadre login --url <url>.`: run `cadre login --url <url>` with the URL the message names, as above. Any `cadre` command can print this line later in a run: sign in again the same way, then run that command again.
- `--url must be an http:// or https:// URL with a host, …`: the URL is not a full address; ask the person for it again.

`cadre login` stores the key itself: the person never types or copies one.

## What to read next

Read the file that holds what the person asked for, and follow it:

- [project.md](project.md): create a project; change, reorder or drop a project or its milestones; show, write or update a milestone's spec; link a milestone to its design. It holds the limits of every field.
- [milestone.md](milestone.md): start a milestone; implement a spec or plan that says it is tracked in Cadre; link a pull request to a milestone.
- [connect.md](connect.md): connect a repo to its Fly app, its Vercel project or its mobile app's stores; connect or disconnect a Fly org, a Vercel team or a store's key; say where a repo deploys, or which build of a mobile app is public.
- [deploy.md](deploy.md): deploy a repo that runs on Fly or Vercel; tick a Before deploying item.

`brainstorm.md` and `design_link.rb` belong to project.md, which says when it needs each.

For a command's flags, run `cadre help <command>`: these files name a flag only to say when to pass it.
