# Draw a project's canvas

A project's canvas is where the team reviews its designs before they are built: one canvas per project, every screen drawn in full context at every size it ships at, styled from the app's own code. Once it is drawn, build its links as "Link a milestone to its design" in [project.md](project.md) says.

## Before you start

Check that your session has the Artifact tool. When it has no Artifact tool, tell the person that drawing the canvas needs a Claude session that can publish artifacts, carry on without `canvas_url` and `design_url`, leaving unset every link this run would set (both are optional, and the canvas can be drawn later), and skip the rest of this file.

## Create the canvas

Create the canvas from the Design artifact type, titled with the project's name, and follow the instructions its create result carries. Build it without a design system, whichever ones the Artifact tool lists: the styles come from the code, as "Styles from the code" says.

This step is done when the canvas exists and you hold its link.

## Styles from the code

Every board takes its colours, type, spacing and components from the app's own code, the app whose screen it shows: the code is the only source that is always up to date.

- For a web app, read its stylesheet, its design tokens and the components the screen uses. For a mobile app, read its theme and the widgets the screen uses.
- Ask before reading a repo other than the current one. A project that changes a web app and a mobile app takes the styles of both.
- When an app has no UI code yet, ask the person where its styles come from.

This step is done when you can name, per app, the files its styles were read from. Name them to the person when you show them the canvas.

## The part pages

- Draw one page per part. A part is a screen or area the project changes, such as "Setup" or "Milestone card": take the parts from the spec's sections. A project with one part has one part page.
- On a part's page, draw one row per milestone that changes that part, in milestone order, each row labelled with the milestone's number and title. A milestone that changes two parts gets a row on each page.
- A row holds, from left to right, the milestone's screens on that part as they look once it ships, each at each of its sizes. Every board is the whole screen in full context: the app's header and navigation and the content around it, at full height.
- A screen the web app has is drawn at 1440, 1024 and 390. A screen the mobile app has, the app of a repo whose `cadre repo show <repo> --json` lists `stores`, is drawn at `phone`, 393 × 852. A screen in both apps gets all four sizes; a screen only the mobile app has gets the phone size alone.
- Name each board `M<n>-<part>-<screen>-<size>.dc.html`: `<part>` is its page's id, `<screen>` is the screen's name in kebab case, and `<size>` is `1440`, `1024`, `390` or `phone`, as in `M3-setup-folders-1440.dc.html`.
- A milestone with no screen gets no board and no `design_url`: its data flow belongs in its pull request, once it is built.

## The review page

After the part pages, add one page with the page id `review`. It shows every screen the project changes in its final state, as it looks once every milestone has shipped: each screen once, grouped by part, at the same sizes as on its part page. Name each board `review-<part>-<screen>-<size>.dc.html`.

The project's `canvas_url` opens this page, so whoever clicks Approve the design in Cadre lands on what they approve.

## Check the canvas

Read `boards` in `project/canvas.json`, and check that:

- every milestone with a screen has its `M<n>-<part>-<screen>-<size>` boards for every part it changes, at the sizes its screen has;
- every screen the project changes has its `review-` boards, at the same sizes.

Open each board, and check that it shows the app's header and navigation, at full height.

Draw what is missing. This step is done when every check holds.

## Add a milestone to a canvas

When a project gains a milestone with a screen, read `pages` in the canvas's `project/canvas.json`:

- When `pages` has a `review` page, add the milestone's rows to the pages of the parts it changes, with a new part page before `review` for a part the canvas lacks, and update the review page to the new final states. Then check the canvas again.
- When `pages` has no `review` page, the canvas predates these rules: give the milestone its own page, named with its number and title, its screens in full context at the sizes "The part pages" gives.

This step is done when the milestone's boards exist and, on a canvas with a `review` page, every check in "Check the canvas" holds.
