---
name: cadre
description: Cadre CLI. Use when asked to create, read, change or drop a Cadre project, milestone or spec, or draw a project's design canvas; start a milestone ("start milestone <project>/<n>"), implement a spec or plan tracked in Cadre or link its pull request; connect a repo or mobile app to where it deploys or releases, or ask where; deploy a Fly or Vercel repo, `cadre link` its checkout, tick a Before deploying item, or ask what can deploy or what's next on a Cadre project; write a repo's Skills table; or sign in to Cadre.
---

# Cadre

Cadre shows where every milestone of a feature stands, on every repo, in deploy order.

To write a repo's Skills table, go straight to [skills.md](skills.md): it runs no `cadre` command.

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
- When it reports a version below `0.23.0`, run `cadre upgrade`: it prints `Upgraded cadre from <old> to <new>.` When it fails, tell the person what it printed, and stop.

## Sign in

Run `cadre whoami --json`. It succeeds when the exit code is 0 and the JSON holds an `email`.

- `Not signed in. Run cadre login --url <url>.`:
  1. Ask the person for their Cadre URL, the address they open Cadre at in their browser, such as `https://cadre.example.com`. The URL comes from the person alone.
  2. Run `cadre login --url <url>` with it in the background (Bash `run_in_background`): it waits up to 10 minutes for the person to click **Allow**, and a foreground command shows its output only once it exits.
  3. Read its first two output lines, `Opening <uri> in your browser.` and `Check that the page shows this code: <code>`, and tell the person the URL and the code: they check that the page shows that code, then click **Allow**.
  4. Wait for the command to exit and read `Signed in as <email>.`
- `Your key for <url> is no longer valid. Run cadre login --url <url>.`: run `cadre login --url <url>` with the URL the message names, as above. Any `cadre` command can print this line later in a run: sign in again the same way, then run that command again.
- `--url must be an http:// or https:// URL with a host, …`: the URL is not a full address; ask the person for it again.
- Any other output from `cadre whoami` or `cadre login`: tell the person what it printed, and stop.

`cadre login` stores the key itself: the person never types or copies one.

## What to read next

Read the file that holds what the person asked for, and follow it:

- [project.md](project.md): create a project; change or reorder a project or its milestones; drop (archive) or bring back a project; show, write or update a milestone's spec; link a milestone to its design; draw a project's canvas. It holds the limits of every field.
- [milestone.md](milestone.md): start a milestone; implement a spec or plan tracked in Cadre; link a pull request to a milestone.
- [connect.md](connect.md): connect a repo to its Fly app, its Vercel project or its mobile app's stores, or record a host other than Fly or Vercel; remove an app; connect or disconnect a Fly org, a Vercel team or a store's key; say where a repo deploys, or which build of a mobile app is public.
- [deploy.md](deploy.md): deploy a repo that runs on Fly or Vercel; remember where a repo's checkout is for cadre's Deploy button (`cadre link`); tick a Before deploying item; answer what can deploy and what's next on a project.
- [skills.md](skills.md): read and check a repo's Skills table when starting a milestone; "Write this repo's Skills table", or draft one when the repo has none.

Before writing, checking or editing a pull request's title or description, load `cadre:pr-description`: it holds the `Cadre:` line and `## Before deploying` rules.

`canvas.md` and `design_link.rb` belong to project.md, which says when it needs each; `skills_table.rb` belongs to skills.md.

For a command's flags, run `cadre help <command>`: these files name a flag only to say when to pass it.

When `cadre` refuses with a line no file names, tell the person what it printed and stop. When that line lists the valid names, ask the person which one, and run the command again with it.
