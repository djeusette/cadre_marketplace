require "minitest/autorun"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

ROOT =File.expand_path("../../..", __dir__)
PLUGIN = File.join(ROOT, "plugins", "cadre")
INSTALL = 'gh release download -R djeusette/cadre_cli --pattern "cadre_$(uname -s)_$(uname -m).tar.gz" -O - | tar -xz -C ~/.local/bin cadre'

module Sections
  # The text under a heading, up to the next heading of the same level or above.
  def section(text, heading)
    level = heading[/\A#+/].length
    text[/^#{Regexp.escape(heading)}\n(.*?)(?=^\#{1,#{level}} |\z)/m, 1] or flunk("no section #{heading}")
  end
end

class ManifestTest < Minitest::Test
  def manifest = JSON.parse(File.read(File.join(PLUGIN, ".claude-plugin", "plugin.json")))
  def marketplace = JSON.parse(File.read(File.join(ROOT, ".claude-plugin", "marketplace.json")))
  def entry = marketplace.fetch("plugins").find { |plugin| plugin["name"] == "cadre" }

  def test_plugin_depends_on_superpowers_alone
    assert_equal "cadre", manifest["name"]
    assert_equal ["superpowers@claude-plugins-official"], manifest["dependencies"]
    assert_equal ["claude-plugins-official"], marketplace["allowCrossMarketplaceDependenciesOn"]
  end

  def test_manifests_name_colette_only_as_the_author
    refute_match(/colette/i, JSON.generate(manifest.except("author")))
    refute_match(/colette/i, JSON.generate(marketplace.merge("plugins" => marketplace["plugins"].map { |plugin| plugin.except("author") })))
  end

  def test_readme_installs_cadre_with_superpowers
    readme = File.read(File.join(ROOT, "README.md"))
    install = "/plugin marketplace add anthropics/claude-plugins-official\n/plugin marketplace add djeusette/cadre_marketplace\n/plugin install cadre@cadre"
    [install, "installs `superpowers` from `claude-plugins-official` with it"].each { |text| assert_includes readme, text }
    assert_includes readme.sub(/^- \*\*cadre\*\* — .*$/, ""), "cadre's skills need superpowers 7.0 or later"
    refute_includes readme, "needs no other plugin"
    refute_includes readme, "without it cadre fails to load"
    refute_match(/colette/i, readme.sub("(https://colette-cadre.fly.dev)", ""))
  end

  def test_marketplace_is_cadre_and_links_its_repo
    assert_equal "cadre", marketplace["name"]
    assert_equal "https://github.com/djeusette/cadre_marketplace", manifest["repository"]
  end

  def test_marketplace_lists_cadre_last_at_the_plugin_version
    assert_equal "cadre", marketplace.fetch("plugins").last["name"]
    assert_equal "./plugins/cadre", entry["source"]
    assert_equal "0.34.0", manifest["version"]
    assert_equal manifest["version"], entry["version"]
  end

  def test_descriptions_match
    refute_empty manifest["description"]
    assert_equal manifest["description"], entry["description"]
    assert manifest["description"].start_with?("Run Cadre from Claude Code: "), manifest["description"]
  end

  def test_readme_leaves_the_release_steps_to_agents_md
    readme = File.read(File.join(ROOT, "README.md"))
    assert_includes readme, "To release a plugin, follow \"Release\" in [AGENTS.md](AGENTS.md)."
    refute_includes readme, "bumping its version"
  end

  def test_readme_lists_cadre
    assert_match(/^- \*\*cadre\*\* — /, File.read(File.join(ROOT, "README.md")))
  end

  def test_readme_sums_cadre_up_and_links_its_skill
    bullet = File.read(File.join(ROOT, "README.md"))[/^- \*\*cadre\*\* — .*?(?=^#|\z)/m]
    assert_includes bullet, "(plugins/cadre/skills/cadre/SKILL.md)"
    assert_includes bullet, "[`cadre:brainstorming`](plugins/cadre/skills/brainstorming/SKILL.md) brainstorms a feature into a Cadre project"
    assert_includes bullet, "[`cadre:pr-description`](plugins/cadre/skills/pr-description/SKILL.md) sets the standard for PR descriptions."
    assert_operator bullet.split.size, :<=, 70
  end

  def agents_md = File.read(File.join(ROOT, "AGENTS.md"))

  def test_agents_md_names_the_checks_the_release_and_which_skill_wins
    ["`LANG=en_US.UTF-8 ruby plugins/cadre/test/plugin_test.rb`", "invalid byte sequence in US-ASCII",
     "change the test first, watch it go red, then the text", "`test_marketplace_lists_cadre_last_at_the_plugin_version`",
     "`mattpocock-skills:writing-for-agents` wins", "starts with `Cadre`",
     "enable its plugin under `enabledPlugins` in `.claude/settings.json`"].each { |text| assert_includes agents_md, text }
    assert_includes ManifestTest.public_instance_methods, :test_marketplace_lists_cadre_last_at_the_plugin_version
    refute_includes agents_md, "Rules for any agent"
    assert_match(/^The cadre skill's description starts with `Cadre`\.$/, agents_md)
    refute_includes agents_md, "wins, and the skill's description"
  end

  def test_agents_md_skills_table_has_no_problems
    out, status = Open3.capture2("ruby", File.join(PLUGIN, "skills", "cadre", "skills_table.rb"), ROOT)
    assert status.success?, out
    result = JSON.parse(out)
    assert result["table"]
    assert result["imports_agents_md"]
    assert_equal [], result["rows"].flat_map { |row| row["problems"] }
    assert_equal [], result["unlisted"]
  end
end

class SkillTest < Minitest::Test
  FEATURE_LINE = %q{> Tracked in Cadre as `<slug>`. Implement each increment with the `cadre:cadre` skill ("start milestone <slug>/<i>"), which plans it and links its pull request to its milestone.}
  MILESTONE_LINE = %q{> Tracked in Cadre as `<slug>/<n>`. Implement it with the `cadre:cadre` skill ("start milestone <slug>/<n>"), which plans it and links its pull request to the milestone.}
  PLAN_LINE = %q{> **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n>`.}
  KEY_LINE = "Your key for <url> is no longer valid. Run cadre login --url <url>."
  TOKEN_GUARDRAIL = "You never see or carry a token, a key or a key file: when the person offers one in chat, leave it unused and send them to its command above, in their own terminal."
  SKILL_DIR = File.join(PLUGIN, "skills", "cadre")
  BRANCHES = %w[project.md milestone.md connect.md deploy.md skills.md]

  def read(name) = File.read(File.join(SKILL_DIR, name))
  def skill = read("SKILL.md")
  def project = read("project.md")
  def milestone = read("milestone.md")
  def connect = read("connect.md")
  def deploy = read("deploy.md")
  def everything = ["SKILL.md", *BRANCHES].map { |name| read(name) }.join("\n")
  def skill_files = Dir[File.join(PLUGIN, "skills", "**", "*")].select { |path| File.file?(path) }

  include Sections

  def frontmatter = skill[/\A---\n(.*?)\n---\n/m, 1]
  def description = frontmatter[/^description: (.*)$/, 1]

  # SKILL.md: what every branch needs, and the router.

  def test_frontmatter_has_only_name_and_description
    assert_match(/^name: cadre$/, frontmatter)
    assert_equal %w[description name], frontmatter.lines.map { |line| line[/\A(\w+):/, 1] }.compact.sort
    assert_operator description.length, :<=, 1024
    assert_match(/Use when/, description)
  end

  def test_the_description_starts_with_cadre_and_stays_short
    assert description.start_with?("Cadre"), description
    assert_operator description.split.size, :<=, 100
  end

  def test_the_description_has_a_trigger_for_every_branch
    { "project.md" => "create, read, change or drop a Cadre project, milestone or spec",
      "milestone.md" => "start a milestone (\"start milestone <project>/<n>\")",
      "connect.md" => "connect a repo or mobile app to where it deploys or releases",
      "deploy.md" => "deploy a Fly or Vercel repo",
      "skills.md" => "write a repo's Skills table",
      "SKILL.md" => "sign in to Cadre" }.each { |branch, text| assert_includes description, text, branch }
    assert_includes description, "what's next on a Cadre project"
    assert_includes description, "draw a project's design canvas"
  end

  def test_the_opening_says_what_cadre_is_and_nothing_a_branch_says
    ["You register a project there", "brainstorm it with the person first"].each { |text| refute_includes skill, text }
  end

  def test_a_skills_table_request_skips_the_cli_steps
    assert_includes skill[/\A.*?(?=^## Before you start)/m], "To write a repo's Skills table, go straight to [skills.md](skills.md): it runs no `cadre` command."
  end

  def router = section(skill, "## What to read next")

  def router_line(name) = router.lines.find { |line| line.include?("[#{name}]") }

  def test_the_router_names_every_branch_a_file_handles
    ["drop (archive) or bring back a project"].each { |text| assert_includes router_line("project.md"), text }
    ["remove an app", "record a host other than Fly or Vercel"].each { |text| assert_includes router_line("connect.md"), text }
  end

  def test_the_router_names_every_file_and_every_file_it_names_exists
    linked = router.scan(/\]\(([^)]+)\)/).flatten
    assert_equal BRANCHES, linked
    linked.each { |name| assert File.file?(File.join(SKILL_DIR, name)), name }
    (Dir.children(SKILL_DIR) - ["SKILL.md"]).each { |name| assert_includes router, name }
  end

  def test_every_link_between_skill_files_leads_to_a_file
    skill_files.select { |path| path.end_with?(".md") }.each do |path|
      File.read(path).scan(/\]\(([^):]+)\)/).flatten.each do |target|
        assert File.file?(File.join(File.dirname(path), target)), "#{File.basename(path)} links #{target}"
      end
    end
  end

  def test_skill_md_keeps_what_every_branch_needs_and_routes_the_rest
    assert_equal ["## Before you start", "## Install or update the CLI", "## Sign in", "## What to read next"], skill.scan(/^## .*$/)
    assert_operator skill.split.size, :<, 1000
    { project => ["## Create a project", "## Write a milestone's spec", "## Link a milestone to its design",
                  "## Update a milestone's spec", "## Change a project", "## Limits"],
      milestone => ["## Start a milestone", "## Track a milestone's implementation", "## Link a pull request by hand"],
      connect => ["## A Fly app", "## A Vercel app", "## A mobile app", "## Any other host", "## Remove an app"],
      deploy => ["# Deploy a repo", "## What can deploy, and what's next", "## Tick a Before deploying item", "## Open Deploy in the right folder"] }.each do |text, headings|
      headings.each { |heading| assert_match(/^#{Regexp.escape(heading)}$/, text) }
    end
  end

  def install_section = section(skill, "## Install or update the CLI")

  def test_it_installs_a_missing_cli_and_upgrades_an_old_one
    assert_includes install_section, INSTALL
    ["When the command is missing,", "below `0.23.0`", "run `cadre upgrade`"].each { |text| assert_includes install_section, text }
    ["0.1.0", "below `0.21.0`", "below `0.19.0`", "below `0.18.0`", "below `0.17.0`", "below `0.16.0`", "below `0.15.0`", "below `0.14.0`", "below `0.13.0`", "below `0.12.0`", "below `0.11.0`", "below `0.2.0`", "below `0.3.0`", "below `0.4.0`", "below `0.5.0`", "below `0.6.0`", "below `0.7.0`", "below `0.8.0`"].each { |text| refute_includes everything, text }
  end

  def sign_in = section(skill, "## Sign in")

  def test_it_asks_the_person_for_the_cadre_url
    ["Ask the person for their Cadre URL", "The URL comes from the person alone", "cadre login --url <url>"].each { |text| assert_includes sign_in, text }
    refute_match(/colette-cadre\.fly\.dev|CADRE_URL/, everything)
    refute_match(/run `cadre login`(?! --url)/, everything)
  end

  def test_it_runs_the_login_in_the_background_and_relays_the_code
    ["Run `cadre login --url <url>` with it in the background (Bash `run_in_background`)", "waits up to 10 minutes",
     "Opening <uri> in your browser.", "Check that the page shows this code: <code>"].each { |text| assert_includes sign_in, text }
    refute_includes sign_in, "600000"
  end

  def test_any_other_sign_in_output_is_relayed_and_stops
    assert_includes sign_in, "- Any other output from `cadre whoami` or `cadre login`: tell the person what it printed, and stop."
  end

  def test_it_uses_the_cli_copy
    ["exit code is 0 and the JSON holds an `email`", "Signed in as <email>.", "Not signed in. Run cadre login --url <url>.", KEY_LINE,
     "--url must be an http:// or https:// URL with a host"].each { |text| assert_includes sign_in, text }
  end

  def test_a_key_that_stops_working_is_answered_once_for_every_command
    assert_includes sign_in, "Any `cadre` command can print this line later in a run: sign in again the same way, then run that command again."
    assert_equal 1, everything.scan(KEY_LINE).size
    BRANCHES.each { |name| refute_includes read(name), "no longer valid", name }
  end

  def test_it_never_asks_for_a_pasted_key
    assert_includes sign_in, "the person never types or copies one"
    refute_match(/paste/i, everything)
  end

  def test_it_points_to_the_clis_help_for_flags
    assert_includes skill, "run `cadre help <command>`"
  end

  def test_an_unnamed_refusal_is_relayed_once_for_every_branch
    assert_includes router, "When `cadre` refuses with a line no file names, tell the person what it printed and stop. When that line lists the valid names, ask the person which one, and run the command again with it."
    refute_includes everything, "its message says what to do"
  end

  def test_it_leaves_what_the_clis_own_message_says_to_the_cli
    ["Try again in a minute", "try again later", "The code expired", "`platform: …`"].each { |text| refute_includes everything, text }
  end

  # project.md

  def create_section = section(project, "## Create a project")
  def write_section = section(project, "## Write a milestone's spec")
  def design_section = section(project, "## Link a milestone to its design")
  def update_section = section(project, "## Update a milestone's spec")
  def change_section = section(project, "## Change a project")
  def repos_section = section(project, "## A milestone's `repos`")
  def project_refusals = section(project, "## When `cadre` refuses")
  def limits = section(project, "## Limits")
  def example = project[/```json\n(.*?)```/m, 1]

  def test_creating_a_project_brainstorms_through_cadre_brainstorming
    assert_includes create_section, "`cadre:brainstorming`"
    refute_includes create_section, "brainstorm.md"
    refute_match(/available skills|must be installed/, everything)
  end

  def test_it_builds_from_a_spec_the_person_names
    ["one with an `## End goal` and an `## Increments` section", "the spec the person names",
     "a likely one in `docs/superpowers/specs/` once you ask and the person confirms it is this feature",
     "This step is done when you hold that spec.",
     "When there is none, or the spec the person names lacks either section, load the `cadre:brainstorming` skill and brainstorm the feature with the person as it says, from that spec when there is one."].each { |text| assert_includes create_section, text }
  end

  def test_it_writes_a_spec_and_draws_the_canvas_through_canvas_md
    ["\"canvas_url\"", "\"design_url\"", "\"spec\""].each { |key| assert_includes example, key }
    ["Draw the project's canvas as [canvas.md](canvas.md) says", "When no milestone has a screen, the project has no canvas"].each { |text| assert_includes create_section, text }
    ["one page per milestone", "remind the person to share", "Claude Design", "diagram"].each { |text| refute_includes create_section, text }
  end

  def test_sharing_is_confirmed_before_registering_a_canvas_the_run_created
    ["When this run created the canvas", "confirm the canvas is shared with the team", "for a new canvas, confirms it is shared",
     "the files each app's styles were read from"].each { |text| assert_includes create_section, text }
    assert_operator create_section.index("confirm the canvas is shared with the team"), :<, create_section.index("cadre project create <file> --json")
  end

  def test_a_milestone_links_the_first_board_of_its_first_row
    ["[design_link.rb](design_link.rb)", "--board <file>", "project/canvas.json", "first board of its first row",
     "earliest part page in `pages`", "the row's first 1440 board", "its phone board", "select the board", "address bar",
     "The project's `canvas_url` links the review page: `--page review`"].each { |text| assert_includes design_section, text }
    [create_section, change_section].each { |text| assert_includes text, 'as "Link a milestone to its design" says' }
    assert_equal ["https://claude.ai/artifact/…#artboard-…"] * 2, example.scan(/"design_url": "([^"]*)"/).flatten
    assert_includes example, "\"canvas_url\": \"https://claude.ai/artifact/…#page-…\""
    ["keeps the canvas link", "page it shares"].each { |text| refute_includes everything, text }
    ["?page=", "claude.ai/design/p/"].each { |text| refute_includes everything + canvas, text }
  end

  def test_project_md_names_its_own_folder_and_the_cadre_skill_for_any_skill_that_follows_it
    ["[design_link.rb](design_link.rb), in project.md's folder", "ruby <project.md's folder>/design_link.rb <canvas_url> --board <file>",
     "ruby <project.md's folder>/design_link.rb <canvas_url> --page review"].each { |text| assert_includes design_section, text }
    assert_includes create_section, "so whoever implements it uses the `cadre:cadre` skill:"
    refute_includes project, "this skill"
  end

  def test_older_canvases_keep_page_links
    ["When `pages` has no `review` page", "--page <id>", "the canvas link stays as it is"].each { |text| assert_includes design_section, text }
  end

  def test_changing_a_project_keeps_the_canvas_link_as_pulled
    ["Keep every `number`, the `slug`, the `version` and the canvas link exactly as pulled",
     "When the person asks to change the canvas link, tell them it clears its design approvals"].each { |text| assert_includes change_section, text }
  end

  def test_a_new_milestone_gets_its_rows_and_its_number_is_reported
    [%q{When the milestone has a screen, draw its designs as "Add a milestone to a canvas" in [canvas.md](canvas.md) says},
     %q{When the project has no canvas yet, follow "Draw a canvas for a project without one" instead: it sets every link},
     "`design_url`", "Report the new number", "its spec and designs come after the update",
     "pull the project again, set that entry's `design_url`"].each { |text| assert_includes change_section, text }
    ["Draw its page in the project's design canvas", "its spec and page come after", "Pull once more", "edit that one entry"].each { |text| refute_includes change_section, text }
  end

  def test_step_9_reports_a_project_without_a_design
    assert_includes create_section, "When the session had no Artifact tool, say the project has no design yet"
  end

  def test_a_project_without_a_canvas_gets_one_later
    later = section(project, "### Draw a canvas for a project without one")
    ["has no `canvas_url` and a milestone with a screen", "[canvas.md](canvas.md)", "`canvas_url`", "`design_url`",
     "confirm the canvas is shared with the team", "Once the person confirms it is shared",
     "cadre project update <file> --json"].each { |text| assert_includes later, text }
    assert_includes router_line("project.md"), "draw a project's canvas"
  end

  def test_its_example_milestones_are_usable_slices_not_layers
    refute_includes example, "The API stores a reminder date"
    assert_includes example, "Members get a reminder before a wish expires"
  end

  def test_nothing_is_registered_before_the_person_approves
    assert_operator create_section.index("Register nothing until the person approves"), :<, create_section.index("cadre project create <file> --json")
  end

  def test_the_feature_spec_says_it_is_tracked_in_cadre
    [FEATURE_LINE, "When a spec the person named lacks the line, add it and leave the commit to them."].each { |text| assert_includes create_section, text }
    assert_includes project_refusals, "change it on the spec's tracking line too"
  end

  def test_a_corrected_spec_is_committed_alone_or_left_to_the_person
    [%q{commit only the spec file, with the `git` commands "The handoff" in [the brainstorming skill](../brainstorming/SKILL.md) gives}, "leave the commit to them"].each { |text| assert_includes create_section, text }
    ["git commit", "never push"].each { |text| refute_includes create_section, text }
  end

  def test_it_reports_the_json_url_and_explains_zero_based_paths
    assert_includes create_section, "`url` field"
    assert_includes create_section, %q{On a `422`, fix it as "When `cadre` refuses" says.}
    refute_includes create_section, "then run the command again"
    ["0-based positions", "milestones.1.repos.0"].each { |text| assert_includes project_refusals, text }
    refute_includes everything, "Report the URL from"
  end

  def test_it_turns_the_spec_into_bare_repo_names
    ["bare", "not `acme/shop-api`", "gh repo view --json name -q .name", "A file path is not a repo name",
     "Take a repo name only from the spec or from the person, and ask when unsure", "the repo that must deploy first listed first"].each { |text| assert_includes repos_section, text }
  end

  def test_it_names_a_milestones_apps
    ["cadre repo show <repo> --json", '"repos": ["kinfield/kinfield", "kinfield/kinfield-family"]', "the API before the frontend",
     "A repo with one app stays a bare repo", "When the spec doesn't say which apps, ask the person",
     "A milestone lists a repo one way only: bare, or by its apps",
     "No repo <repo> on <server>.", "stays a bare `repo` unless the spec names its apps"].each do |text|
      assert_includes repos_section, text
    end
    assert_includes create_section, %q{its `repos` as "A milestone's `repos`" says}
    ["the API before the frontend", "isn't connected yet"].each { |text| assert_equal 1, repos_section.scan(text).size, text }
    assert_includes repos_section, "A repo with several apps, or a one-app repo with that app still to connect, gets one `repo/app` entry per app the milestone expects"
    refute_includes repos_section, "That repo, and"
    assert_includes change_section, %q{name their apps, as "A milestone's `repos`" says}
    assert_includes limits, "| `repos` | 1–10 per milestone, no repeats, each `repo` or `repo/app`"
  end

  def test_a_milestones_spec_says_it_is_tracked_in_cadre
    assert_includes write_section, MILESTONE_LINE
  end

  def test_a_milestones_spec_holds_only_its_part_of_the_feature_spec
    assert_includes write_section, "It holds only this milestone's part of the feature spec"
    ["Not shipped", "It has no"].each { |text| refute_includes write_section, text }
  end

  def test_it_pulls_a_spec_edits_it_and_pushes_it_with_its_base
    ["update the spec of", "cadre spec pull <project>/<n> -o <file> --json", "cadre spec push <project>/<n> <file> --json", "--base <version>",
     "has no spec yet.", "previous version", "pull again first"].each { |text| assert_includes update_section, text }
    ["changed since you pulled it. Pull it again.", "tell the person who (`updated_by`)", "No milestone <project>/<n> on <server>."].each do |text|
      assert_includes project_refusals, text
    end
  end

  def test_a_push_leaves_design_links_to_changing_a_project
    assert_includes update_section, %q{A push changes only the spec; a design link changes as "Change a project" says.}
    ["exactly as Cadre stores it", "exactly as written", "a design link is set when the project is created"].each { |text| refute_includes update_section, text }
  end

  def test_it_shows_a_spec_under_its_own_heading
    assert_includes section(project, "## Show a milestone's spec"), "`cadre spec pull <project>/<n>`"
    refute_includes update_section, "To show the person a spec"
  end

  def test_it_no_longer_asks_before_replacing_a_spec
    ["nothing shows it yet", "ask the person before pushing"].each { |text| refute_includes everything, text }
  end

  def test_it_changes_and_archives_a_project
    ["cadre project pull <slug> -o <file> --json", "cadre project update <file> --json", "cadre project archive <slug>",
     "cadre project unarchive <slug>", "its number is retired for good", "only once the person agrees"].each { |text| assert_includes change_section, text }
    ["<slug> changed since you pulled it", "is archived. Run cadre project unarchive", "No project <slug> on <server>.",
     "milestones.<i>.number: …"].each { |text| assert_includes project_refusals, text }
  end

  def test_changing_a_project_names_no_colette_skill
    refute_match(/colette:/, change_section)
  end

  def test_a_new_milestone_gets_its_spec_once_cadre_has_numbered_it
    assert_includes change_section, "cadre spec push <slug>/<n> <spec-file> --json"
    assert_includes change_section, "Pull the project again"
    assert_includes change_section, "no `number`, no `spec` and no `design_url`"
    assert_includes change_section, "leave `spec` out of its entry"
    refute_match(/with its spec written as/, change_section)
    assert_operator change_section.index("cadre project update <file> --json"), :<, change_section.index("cadre spec push <slug>/<n>")
    refute_includes change_section, "spec push <slug>/<n> <spec-file> --base"
  end

  def test_an_unarchived_project_keeps_its_file
    assert_includes change_section, "continue with the same file: unarchiving doesn't change the version"
  end

  def test_limits_name_the_spec_and_link_rules
    ["100 000", "not blank", "https://", "2 000"].each { |text| assert_includes limits, text }
  end

  # canvas.md

  def canvas = read("canvas.md")

  def test_canvas_md_belongs_to_project_md
    assert_includes skill, "`canvas.md` and `design_link.rb` belong to project.md"
    refute_includes skill, "brainstorm.md"
    ["# Draw a project's canvas", "## Before you start", "## Create the canvas", "## Styles from the code", "## The part pages",
     "## The review page", "## Check the canvas", "## Add a milestone to a canvas"].each { |heading| assert_match(/^#{Regexp.escape(heading)}$/, canvas) }
  end

  def test_the_canvas_is_one_per_project_from_the_design_type
    ["one canvas per project", "Design artifact type", "follow the instructions its create result carries"].each { |text| assert_includes canvas, text }
  end

  def test_the_canvas_builds_without_a_design_system
    styles = section(canvas, "## Styles from the code")
    ["the app's own code", "the files its styles were read from", "Ask before reading a repo other than the current one",
     "ask the person where its styles come from"].each { |text| assert_includes styles, text }
    create = section(canvas, "## Create the canvas")
    ["Build it without a design system", "whichever ones the Artifact tool lists"].each { |text| assert_includes create, text }
    refute_includes create, "When that result lists design systems"
  end

  def test_part_pages_hold_a_row_per_milestone_in_full_context
    parts = section(canvas, "## The part pages")
    ["one page per part", "the spec's sections", "one row per milestone", "labelled with the milestone's number and title",
     "a row on each page", "`M<n>-<part>-<screen>-<size>.dc.html`", "`<screen>` is", "left to right", "1440, 1024 and 390", "393 × 852",
     "the phone size alone", "`stores`", "header and navigation", "full height", "no board and no `design_url`", "its pull request"].each { |text| assert_includes parts, text }
    refute_includes canvas, "diagram"
    refute_includes canvas, "The project has a mobile app"
  end

  def test_the_review_page_shows_every_final_state
    review = section(canvas, "## The review page")
    ["page id `review`", "final state", "`review-<part>-<screen>-<size>.dc.html`", "at the same sizes", "Approve the design"].each { |text| assert_includes review, text }
  end

  def test_the_canvas_check_reads_its_criteria_from_canvas_json
    check = section(canvas, "## Check the canvas")
    ["`boards` in `project/canvas.json`", "every part it changes", "at the sizes its screen has", "every screen the project changes",
     "Open each board", "header and navigation"].each { |text| assert_includes check, text }
    refute_includes check, "1440, 1024 and 390"
  end

  def test_links_are_left_to_project_md
    assert_equal 1, canvas.scan(%q{as "Link a milestone to its design" in [project.md](project.md) says}).size
    ["--board", "--page", "#artboard-"].each { |text| refute_includes canvas, text }
    refute_includes design_section, "A milestone with no screen"
  end

  def test_an_older_canvas_gets_a_page_per_new_milestone
    add = section(canvas, "## Add a milestone to a canvas")
    ["When `pages` has a `review` page", "update the review page", "Then check the canvas again", "When `pages` has no `review` page",
     "its own page", "This step is done when"].each { |text| assert_includes add, text }
  end

  def test_without_the_artifact_tool_the_project_has_no_design_yet
    ["no Artifact tool", "without `canvas_url` and `design_url`", "skip the rest of this file"].each { |text| assert_includes section(canvas, "## Before you start"), text }
    refute_includes section(canvas, "## Before you start"), "register the project"
  end

  def test_no_skill_file_says_claude_design
    skill_files.each { |path| refute_includes File.read(path), "Claude Design", File.basename(path) }
  end

  # milestone.md

  def start_section = section(milestone, "## Start a milestone")
  def track_section = section(milestone, "## Track a milestone's implementation")
  def link_section = section(milestone, "## Link a pull request by hand")
  def first_step = section(milestone, "## The first step with no pull request")
  def milestone_refusals = section(milestone, "## When `cadre` refuses")

  def test_it_starts_a_milestone_with_one_plan_and_one_pull_request_per_repo
    ["cadre project pull", "cadre spec pull <slug>/<n>", "docs/superpowers/specs/<slug>-<n>.md",
     "in its own session", "gh repo view --json name -q .name",
     %q{as "Update a milestone's spec" in [project.md](project.md) says}].each do |text|
      assert_includes start_section, text
    end
    ["No project <slug> on <server>.", "No milestone <slug>/<n> on <server>."].each { |text| assert_includes milestone_refusals, text }
  end

  def test_it_commits_only_the_spec_copy
    ["git add <path>", 'git commit -m "docs: spec of <slug>/<n>" -- <path>', "cadre reads only its own"].each { |text| assert_includes start_section, text }
  end

  def test_it_works_in_a_hidden_worktree_inside_the_main_checkout
    ["`superpowers:using-git-worktrees`", "The person has agreed to a worktree: make one without asking.",
     "a hidden folder of the main checkout", "`.claude/worktrees/<branch>`", "`.worktrees/<branch>`",
     "`git worktree list`", "git worktree add .worktrees/<branch> <branch>",
     "`git switch -c <branch>`, or `git switch <branch>` when it already exists",
     "This step is done when `git branch --show-current` prints `<branch>` in a worktree under the main checkout.",
     "The main checkout stays on its branch"].each { |text| assert_includes start_section, text }
    assert_equal 1, start_section.scan("git switch -c").size
    assert_operator start_section.index("superpowers:using-git-worktrees"), :<, start_section.index("git add <path>")
    assert_operator start_section.index("`git worktree list`"), :<, start_section.index("`superpowers:using-git-worktrees`")
    ["a native tool makes only new branches", "move into it"].each { |text| assert_includes start_section, text }
    ["git branch --show-current` prints the repo's default branch", "the default branch stays as it was"].each { |text| refute_includes start_section, text }
  end

  def test_it_skips_the_commit_when_the_spec_copy_is_unchanged
    assert_includes start_section, "already holds this text, as when a milestone is started again, skip the commit."
    ["creating the folder", "there is nothing to commit"].each { |text| refute_includes start_section, text }
  end

  def test_step_two_ends_knowing_this_repos_part_and_its_app
    ["This step is done when you know this repo's part and, for one app's pull request, its app.",
     "the app the person named, otherwise the first of this repo's app steps with no pull request",
     "name the step it starts at, the first step with no pull request", "in its own session in that repo"].each { |text| assert_includes start_section, text }
    assert_operator start_section.index("for one app's pull request, its app"), :<, start_section.index("git switch -c <branch>")
  end

  def test_one_pull_request_covers_the_whole_repo_unless_the_work_splits_by_app
    ["When those steps name this repo's apps and the work splits by app, the pull request is for one app",
     "Otherwise one pull request covers every step of this repo, and its `Cadre:` line names no app."].each { |text| assert_includes start_section, text }
    refute_includes start_section, "When they name this repo's apps"
  end

  def test_it_starts_a_milestone_from_its_app_steps
    ["a repo/app entry is its repo", "the first step with no pull request",
     %q{found as "The first step with no pull request" says}, "`<slug>-<n>-<app>` for one app's pull request"].each { |text| assert_includes start_section, text }
    ["cadre status <slug> --json", "`number`", "`steps` in deploy order", "`app` (null for a whole-repo step)",
     "the open and merged `pull_requests` that count on it", "The first step whose `pull_requests` is empty",
     "Ask the person which step is next when every step already has a pull request, or when they say one isn't linked yet",
     "`cadre status` counts only linked pull requests",
     %q{one opened before the cadre GitHub App was installed is linked as "Link a pull request by hand" says}].each { |text| assert_includes first_step, text }
    refute_includes first_step, "When it is unclear"
    ["gh pr list", "<slug>/20", "owner.login"].each { |text| refute_includes milestone, text }
  end

  def test_step_5_hands_over_to_cadre_writing_plans
    assert_includes start_section, "5. Plan this repo's part with the `cadre:writing-plans` skill: load it, and hand it the spec copy's path, this repo's part and, for one app's pull request, its app."
    ["REQUIRED SKILL", "Execute the plan", "\n6. "].each { |text| refute_includes start_section, text }
    refute_includes milestone, "this skill"
  end

  def test_the_pull_request_description_follows_cadre_pr_description
    refute_includes milestone, "## The pull request's description"
    ["reads exactly `Cadre:", "- [ ]"].each { |text| refute_includes milestone, text }
    assert_includes router, "Before writing, checking or editing a pull request's title or description, load `cadre:pr-description`: it holds the `Cadre:` line and `## Before deploying` rules."
  end

  def test_the_pull_request_lists_what_a_deploy_needs_first
    refute_includes milestone, "ticks an item in GitHub"
    assert_includes track_section, "Load `cadre:pr-description` before writing or editing its pull request's description."
  end

  def test_it_tracks_the_implementation_of_a_spec_or_plan
    ["`Cadre:` line", "gh pr view <pr-url> --json body -q .body", "gh pr edit <pr-url> --body-file <file>",
     "its increment `<i>` is milestone `<slug>/<i>`", "as \"Start a milestone\" says"].each { |text| assert_includes track_section, text }
  end

  def test_it_links_a_pull_request_by_hand_and_relays_the_cli_errors
    ["`cadre pr link <pr-url> <slug>/<n> --json`", "`--none` in place of `<slug>/<n>` to unlink it", "`project_url`",
     "A `Cadre:` line in the description overrides this link, so edit that line."].each { |text| assert_includes link_section, text }
    refute_includes link_section, "wins at its next sync"
    ["No milestone <slug>/<n> on <server>.", "GitHub has no pull request at <url>.", "GitHub isn't connected on <server> yet.",
     "tell the person, and stop", %q{as "Change a project" in [project.md](project.md) adds it},
     "url: is in a repo no project names"].each { |text| assert_includes milestone_refusals, text }
  end

  def test_it_links_a_pull_request_to_an_app
    assert_includes link_section, "with `--app <app>` for one app"
    assert_includes milestone_refusals, "app: must be lowercase letters, digits, - or _"
    refute_includes milestone, "as `cadre repo show` lists it"
    refute_includes milestone, "app: needs a milestone"
  end

  # skills.md

  SKILLS_HEADINGS = ["# A repo's Skills table", "## Read the table", "## Check each row", "## Load what the work needs",
                     "## No Skills table", "## Draft a Skills table", "## The table's shape"].freeze

  def skills = read("skills.md")
  def read_table = section(skills, "## Read the table")
  def check_rows = section(skills, "## Check each row")
  def load_skills = section(skills, "## Load what the work needs")
  def no_table = section(skills, "## No Skills table")
  def draft_table = section(skills, "## Draft a Skills table")
  def table_shape = section(skills, "## The table's shape")

  def test_skills_md_has_its_sections
    assert_equal SKILLS_HEADINGS, skills.scan(/^#+ .*$/)
  end

  def test_it_reads_the_table_with_the_script
    assert_includes read_table, %q{ruby <skills.md's folder>/skills_table.rb "$(git rev-parse --show-toplevel)"}
    ["<repo root>", "It prints JSON"].each { |text| refute_includes read_table, text }
  end

  def test_it_stops_on_a_missing_plugin_and_names_its_install_command
    ["among the skills this session can load", "its Install command", "a new session",
     "what the script names", "no row lists", "`@AGENTS.md`", "Check every row before answering",
     "name every such row to the person in one answer, and stop"].each { |text| assert_includes check_rows, text }
    refute_includes check_rows, "Then stop"
    assert_equal 1, check_rows.scan(/\bstop\b/).size
  end

  def test_each_plan_task_names_the_skills_it_needs
    assert_equal "Load every row whose When fits the work, before planning.", load_skills.strip
    assert_includes skills, "Read it whenever you plan, as the `cadre:writing-plans` skill says"
    refute_includes skills, "this skill"
  end

  def test_no_table_offers_to_draft_and_never_blocks
    ["draft it now or go on without it", "Going on without it is always allowed"].each { |text| assert_includes no_table, text }
  end

  def test_drafting_proposes_every_fitting_skill_and_waits_for_the_person
    ["manifests", "user and project settings", "every skill the session can load for that kind of work", "a frontend app gets every frontend skill",
     "neither a plugin nor installable from a public source", "writes nothing until the person confirms", "npx skills add",
     "ln -s ../../.agents/skills/<name> .claude/skills/<name>", ".claude/settings.json", "extraKnownMarketplaces", "@AGENTS.md"].each do |text|
      assert_includes draft_table, text
    end
  end

  def test_the_table_shape_is_exact
    ["| Skill | When | Install |", "committed in .agents/skills/", "claude plugin install <plugin>@<marketplace>",
     "When names the work in plain words (`Ash resources or domains`), not a file glob (`lib/**/*.ex`)."].each { |text| assert_includes table_shape, text }
  end

  def test_skills_md_names_no_skill_of_its_own
    refute_match(/colette|elixir-phoenix|flutter|frontend-design:|vercel:|superpowers:/, skills)
  end

  def test_it_routes_the_skills_table_request
    assert_includes description, "write a repo's Skills table"
    assert_operator description.split.size, :<=, 100
    assert_match(/^- \[skills\.md\]\(skills\.md\): read and check a repo's Skills table when planning; .*"Write this repo's Skills table"/, router)
  end

  def test_each_section_says_where_to_go_next
    ["exits non-zero", "show the person its output and stop", %q{go on to "Check each row"}].each { |text| assert_includes read_table, text }
    assert_includes check_rows, %q{go on to "Load what the work needs"}
    assert_includes no_table, %q{go on to "Load what the work needs"}
    [%q{go on to "Check each row"}, "the milestone's branch", "commit only those files", "while planning"].each { |text| assert_includes draft_table, text }
    refute_includes draft_table, "while starting a milestone"
    refute_includes draft_table, "on their own"
  end

  def test_drafting_ends_once_no_row_has_problems
    assert_includes draft_table, "until the script reports no `problems`, then name any `unlisted` folders"
    refute_includes draft_table, "no `problems` and no `unlisted`"
    assert_includes draft_table, "after the table"
  end

  # connect.md

  def fly_app = section(connect, "## A Fly app")
  def fly_org = section(connect, "### Connect a Fly org")
  def vercel_app = section(connect, "## A Vercel app")
  def vercel_team = section(connect, "### Connect a Vercel team")
  def mobile_app = section(connect, "## A mobile app")
  def store_key = section(connect, "### Connect a store's key")
  def set_again = section(connect, "## Set an app again")
  def status_urls = section(connect, "## Status URLs")
  def tokens_and_keys = section(connect, "## Tokens and keys")
  def target_fields = section(connect, "## A target's fields")
  def connect_refusals = section(connect, "## When `cadre` refuses")

  def test_a_run_connects_one_platform_under_its_own_heading
    ["## A Fly app", "## A Vercel app", "## A mobile app", "## Any other host"].each_cons(2) do |first, second|
      assert_operator connect.index(first), :<, connect.index(second)
    end
    assert_includes connect, %q{follow the one section for where it runs: "A Fly app", "A Vercel app", "A mobile app" or "Any other host"}
    refute_match(/^(6|7|8|9|10|11)\. /, connect)
    assert_includes connect, "Then, by what was asked:\n\n- To connect an app,"
    refute_match(/^\d\. To /, connect)
    assert_includes connect, "To connect or disconnect a Fly org, a Vercel team or a store's key, follow the section of that name under its platform."
    refute_match(/\bstep \d/, connect)
  end

  def test_it_shows_sets_and_unsets_a_repos_targets
    ["cadre repo show <repo> --json", "cadre repo set <repo> --fly-app <app> --json", "cadre repo set <repo> --platform <name> --json", "not tracked",
     "cadre repo unset <repo> --platform <name> --json", "any host other than Fly or Vercel"].each { |text| assert_includes connect, text }
    ["reads as its field names say", "`name` is unique across the repo's platforms", "`status_url` sits next to `settings`, not inside it",
     '`live` is `"live"`, `"not_live"`, `"not_checked"`, or `null` with nothing to check',
     "`stores` is empty for any app but a mobile one", "That is expected"].each { |text| assert_includes target_fields, text }
    ["`platform`;", "`not_live_since`", "`last_deploy`", "`tracked`: whether"].each { |text| refute_includes target_fields, text }
    assert_includes connect, %q{"where does it release?" or "which build is public?" from `stores`}
    refute_includes connect, "`null` for Fly"
  end

  def test_it_asks_whether_an_app_is_a_further_one_or_a_move
    ["a further app or a move", "--name <existing>", "read `cadre repo show <repo> --json` again", "--fly-config <file>",
     "Report the target the JSON body holds"].each { |text| assert_includes fly_app, text }
    refute_includes everything, "To move an app instead"
    ["umbrella", "Cadre finds the connected", "takes the Fly app's name", "a monorepo has several"].each { |text| refute_includes connect, text }
  end

  def test_it_connects_a_fly_org_once_the_person_agrees_and_pipes_its_token
    ["Ask the person first", "fly tokens create readonly -o <org> -n cadre | cadre fly org add <org>", %q{as "Tokens and keys" says},
     "cadre fly org remove <org>", "in their own terminal", "No token given. Pipe it in, or type it when asked."].each { |text| assert_includes fly_org, text }
    assert_operator fly_org.index("Ask the person first"), :<, fly_org.index("| cadre fly org add <org>")
    ["<token>", "--token"].each { |text| refute_includes connect, text }
  end

  def test_it_connects_vercel_apps_and_teams
    ["--vercel-project", "--name <app>", "--vercel-dir", "`cadre deploy <repo>` deploys it, as [deploy.md](deploy.md) says",
     %q{3. Read the answer's `status_url` as "Status URLs" says for Vercel.}].each { |text| assert_includes vercel_app, text }
    assert_equal 1, connect.scan("status_url_note").size
    ["cadre vercel team add", "cadre vercel team remove", "Account Settings, then Tokens", "a token scoped to the team",
     "`vercel tokens add` can only make a token for the whole account", "in their own terminal", "team-scoped", "dashboard",
     %q{as "Tokens and keys" says}].each { |text| assert_includes vercel_team, text }
  end

  def test_it_names_the_tag_a_mobile_build_needs
    ["4. Once the app is connected, tell the person", "`prod-v<version>-<build>` on the commit it was built from", "`stg-v<version>-<build>`", "`prod-v1.8.15-6188`", "`pubspec.yaml`",
     "run \"Tag each build\"", "### Tag each build", "`cadre repo show <repo> --json`", "`public_build.tag`",
     "When `public_build` is `null`, the store has no public build yet: there is nothing to tag.",
     "When it is `null`, a public build is a production build", "(its `version` and `build_number`)",
     "Ask the person for the commit the build was made from, since cadre has no commit for an untagged build.",
     "When `version` is `null` (Google Play gives none), read the version from `pubspec.yaml` at that commit.",
     "for them to run in a checkout of that repo: `git tag <tag> <commit> && git push origin <tag>`", "The person runs it, never you."].each { |text| assert_includes connect, text }
    refute_includes connect, "`public_build.commit`"
    tag_each_build = connect[/### Tag each build\n.*?(?=\n### )/m]
    assert_equal 5, tag_each_build.scan(/^\d+\. /).size
    assert_operator tag_each_build.index("Ask the person for the commit"), :<, tag_each_build.index("`pubspec.yaml`")
  end

  def test_it_connects_a_mobile_app
    ["--app-store-app <id>", "--play-package <name>", "Apple ID", "one store or both", "Apps page", "Report the stores"].each { |text| assert_includes mobile_app, text }
    assert_includes set_again, "setting the app again replaces its stores. Pass both each time for an app on both stores, and the one it has for an app on one. A store left out is taken off."
    assert_includes status_urls, "takes no status URL: cadre refuses `--status-url` for it"
    assert_equal 1, connect.scan("refuses `--status-url`").size
    assert_includes connect_refusals, "- `App Store: no connected key reads <id> (asked: <key-id>)`"
  end

  def test_a_store_key_is_added_by_the_person
    ["cadre app-store key add <key-id> --issuer <issuer-id>", "cadre google-play account add", "their own terminal", "Setup page",
     %q{as "Tokens and keys" says}, "cadre app-store key remove <key-id>", "cadre google-play account remove <email>"].each { |text| assert_includes store_key, text }
  end

  def refusal(text, prefix) = text[/^- `#{Regexp.escape(prefix)}.*$/] || flunk("no refusal #{prefix}")

  def test_a_missing_refusal_line_fails
    error = assert_raises(Minitest::Assertion) { refusal("- `Something else.`", "No such refusal.") }
    assert_equal "no refusal No such refusal.", error.message
  end

  def test_it_reads_a_mobile_app_s_stores_field_by_field
    ["a store's `public_build` is `null` until cadre saw one", "A mobile app's own `account` is `null` and its `tracked` is `false`",
     "It is not a sign that the app isn't connected",
     "cadre reads the build's tag, so it knows the build's commit once the tag is pushed",
     "until a build public on every store has its tag", "its card lists the PRs each build holds",
     "until then its merged PRs stay Merged"].each { |text| assert_includes target_fields, text }
    refute_includes connect, "later release"
    ["has a `label`", "its `build_number` and `since`"].each { |text| refute_includes target_fields, text }
    assert_includes connect, %q{Answer "where does it deploy?" from these fields, and "where does it release?" or "which build is public?" from `stores`}
  end

  def test_it_asks_for_the_ids_a_mobile_app_needs
    ["the number in its App Store Connect address (`6443635924`)", "the Google Play package name (`com.example.app`)",
     "with `--name <app>` when the repo has more than one app"].each { |text| assert_includes mobile_app, text }
  end

  def test_it_says_once_when_cadre_shows_a_store_s_public_build
    ["each with the key or account that reads it",
     "cadre shows each store's public build on its Apps page within 15 minutes"].each { |text| assert_includes mobile_app, text }
    refute_includes connect, "Cadre asks each store which build is public"
    assert_equal 1, connect.scan("15 minutes").size
  end

  def test_a_store_key_file_is_asked_for_in_the_persons_terminal_and_never_read
    ["which asks for the key's `.p8` file", "which asks for the service account's JSON key file",
     "Once they say it is added, set the app that was waiting for it"].each { |text| assert_includes store_key, text }
    assert_includes tokens_and_keys, TOKEN_GUARDRAIL
  end

  def test_it_explains_the_no_connected_key_error
    ["no connected key or account reads that app", "The parentheses say what cadre asked", "Check the Apple ID or the package name with the person",
     %q{as "Connect a store's key" says}].each { |text| assert_includes refusal(connect_refusals, "App Store: no connected key reads"), text }
  end

  def test_it_explains_the_https_only_refusal
    line = refusal(connect_refusals, "Cadre sends a key or a token over https only. Sign in to an https address first: cadre login --url https://<your cadre>.")
    ["isn't https, and nothing was sent", %q{Sign in again as "Sign in" in [SKILL.md](SKILL.md) says, with the person's https URL},
     "then the person runs their add again in their own terminal, or you run the Fly pipe again."].each { |text| assert_includes line, text }
    refute_includes line, "the add runs again"
    refute_match(/(tell|show) the person what (it|fly|vercel) printed|relay/i, connect)
  end

  def test_a_new_app_store_key_means_setting_its_apps_again
    ["set again each app the old key read", "The old key stays connected until then.", "a new JSON key"].each { |text| assert_includes store_key, text }
    ["<key-id> still reads <repos>.", "then remove this one.", "Do that in that order with the person"].each { |text| assert_includes connect_refusals, text }
  end

  def test_a_token_or_key_never_passes_through_claude_code
    ["without passing through Claude Code", "in their own terminal", "for a Fly org only, the pipe",
     "Ask the person only for names and IDs.", TOKEN_GUARDRAIL].each { |text| assert_includes tokens_and_keys, text }
    refute_includes connect, "print it, echo it"
    refute_includes connect, "These two ways are the only ones"
  end

  def test_it_removes_an_app_by_name
    assert_includes section(connect, "## Remove an app"), "cadre repo unset <repo> --name <app> --json"
    assert_includes section(connect, "## Remove an app"), "once the person confirms"
    refute_includes connect, "--platform vercel --name <app>"
  end

  def test_it_asks_for_a_status_url_when_it_connects_a_repo
    ["--status-url", "https", "2xx", "isn't monitored", "every 2 minutes", "health checks", "Deployed", "mobile",
     "production domain", "--no-status-url", "status_url_note", "without redirecting", "login page"].each { |text| assert_includes status_urls, text }
    [fly_app, vercel_app].each { |text| assert_includes text, %q{as "Status URLs" says} }
    refute_includes everything, "Don't ask for a status URL"
    refute_includes everything, "takes none yet"
    ["Pass it as `--status-url <url>`", "When `cadre` refuses the URL"].each { |text| refute_includes status_urls, text }
  end

  def test_setting_an_app_again_is_said_once_and_carries_every_setting_over
    ["Setting an app again (the same name) replaces its settings", "Read what is there before setting it", "Carry them over",
     "**Fly:** every flag `cadre help repo set` says a set replaces.",
     "A status URL left out is replaced by the production domain when it answers, and removed otherwise",
     "A Vercel target whose `status_url` is `null` keeps none only with `--no-status-url`, so ask the person whether it should stay unmonitored or take the default"].each do |text|
      assert_includes set_again, text
    end
    assert_equal 1, everything.scan(/replaces its settings/).size
    refute_includes connect, "`--fly-app`, `--fly-config` and `--status-url` each time"
    refute_match(/setting a platform again/i, everything)
  end

  def test_it_relays_the_deploy_target_errors
    ["Fly isn't connected on <server> yet. Add an org with cadre fly org add <org>.",
     "settings.app: isn't an app of a connected Fly org (", "Fly refused this token for <org>.",
     "Fly has no org <org> that this token can read.", "<org> still reads <repos>. Unset or move those targets first.",
     "No repo <repo> on <server>.",
     %q{as "Change a project" in [project.md](project.md) does}].each { |text| assert_includes connect_refusals, text }
  end

  def test_it_explains_the_vercel_error_lines
    ["Vercel isn't connected on <server> yet. Add a team with cadre vercel team add <team>.",
     "settings.project: isn't a project of a connected Vercel team (…)",
     "Vercel refused this token for <team>.", "Vercel has no team <team> that this token can read.",
     "<team> still reads <repos>. Unset or move those targets first."].each { |text| assert_includes connect_refusals, text }
  end

  def test_it_relays_the_refusals_of_an_app_by_name
    assert_includes connect_refusals, "<app> is already the <Platform> app of <other>, an app of <repo>. Set <other> instead, or unset it first."
    ["<name> is already a <Platform> app of <repo>. Unset it first.", "<repo> has <n> <Platform> apps: <apps>. Pass --name <app>.",
     "No Fly org <org> on <server>.", "No Vercel team <team> on <server>.", "there is nothing to remove"].each { |text| refute_includes connect, text }
  end

  def test_a_name_on_a_host_cadre_cant_read_is_set_again_without_it
    assert_includes refusal(connect_refusals, "name: isn't used on this platform`"),
                    "a host cadre can't read takes no `--name`. Set it with `--platform <name>` alone."
  end

  def test_it_relays_the_name_format_refusals
    ["`name: is required`", "`name: must be lowercase letters, digits, - or _`"].each { |text| assert_includes connect_refusals, text }
  end

  # deploy.md

  def deploy_steps = section(deploy, "# Deploy a repo")[/\A.*?(?=^## )/m]
  def deploy_anyway = section(deploy, "## Deploy anyway?")
  def tick_section = section(deploy, "## Tick a Before deploying item")
  def deploy_stops = section(deploy, "## When a deploy stops")
  def status_section = section(deploy, "## What can deploy, and what's next")

  def test_it_answers_what_can_deploy_and_what_is_next_from_cadre_status
    ["cadre status --json", "cadre status <slug> --json", "`can_deploy`", "`held`", "`blocked_by`", "`nothing_to_ship`", "`not_tracked`",
     "`next_step.text`", "in cadre's words", "answer from cadre alone: a status question deploys nothing"].each { |text| assert_includes status_section, text }
    ["rephrase", "Don't guess", "don't deploy"].each { |text| refute_includes status_section, text }
  end

  def test_it_looks_a_project_up_by_name_before_asking_for_its_status
    ["takes its slug", "`slug` of the entry of `cadre status --json`'s `projects` whose `name` matches",
     "ask which when none or several do", "use what the person typed as the slug when it is one"].each { |text| assert_includes status_section, text }
    refute_includes status_section, "cadre status <project>"
    assert_operator status_section.index("`slug` of the entry"), :<, status_section.index("cadre status <slug> --json")
  end

  def test_it_says_a_project_without_a_next_step_is_finished_or_archived
    assert_includes status_section, "When `next_step` is null, say the project is finished or archived, as `group` says."
  end

  def test_it_lists_each_project_s_next_step_when_no_project_is_named
    assert_includes status_section, "\"What's next?\" with no project named: run `cadre status --json` and give each project's `name` with its `next_step.text`"
  end

  def test_it_deploys_with_cadre_deploy_once_the_person_confirms
    ["cadre deploy <repo>", "Confirm first: a deploy can't be taken back.", "Once the person confirms", "600000", "run_in_background",
     "last_deploy", "commit unknown", "lists them as `targets`, each with a `name` and a `platform`",
     "It is done when the target's `last_deploy.commit` is the commit deployed.",
     "check once more a minute later. When it still doesn't, tell the person Cadre shows it once it wakes, and stop."].each { |text| assert_includes deploy_steps, text }
    assert_operator deploy_steps.index("Confirm first"), :<, deploy_steps.index("run the command in a checkout")
    ["fly deploy", "vercel deploy", "git status --porcelain", "without the confirmation"].each { |text| refute_includes deploy, text }
  end

  def test_cadre_deploy_is_the_one_way_to_deploy
    assert_includes deploy_steps, "`cadre deploy` is the one way to deploy here, whatever stops it. Never run a `fly` or `vercel` command to deploy."
  end

  def test_it_asks_which_app_to_deploy
    ["cadre repo show <repo> --json", "--app <name>", "--all", "only when the person asks for every app",
     "the deploy order puts first"].each { |text| assert_includes deploy_steps, text }
    ["<repo> has <n> apps: <apps>. Pass --app <name> or --all.", "<repo> has <n> apps: <apps>. Pass --app <name>, in deploy order.",
     "<repo> has apps on more than one platform. Deploy each with --app <name>, in deploy order.",
     "each once the person confirms"].each { |text| assert_includes deploy_stops, text }
    refute_includes deploy, "cadre deploy can't deploy it yet"
  end

  def test_it_says_a_mobile_app_releases_through_the_stores
    assert_includes refusal(deploy_stops, "<repo>'s releases go through the stores."), "the app is a mobile app, and nothing is deployed"
    assert_includes deploy_stops, "Apps page"
    refute_includes deploy_steps, "mobile"
  end

  def test_it_deploys_vercel_repos_too
    ["runs on Fly or Vercel", "has no .vercelignore", "lacks what"].each { |text| assert_includes deploy, text }
  end

  def test_deploy_md_leaves_relaying_cadres_own_lines_to_skill_md
    assert_includes deploy_steps, %q{It stopped on a check or failed: follow "When a deploy stops" for the line it printed.}
    refute_match(/(tell|show) the person what (it|fly|vercel) printed|relay/i, deploy)
    ["isn't installed", "isn't signed in", "Any other failure is fly's own", "doesn't know the project", "has no app <app>. Its apps",
     "'s build failed:", "built but didn't go live", "cadre stopped while promoting"].each { |text| refute_includes deploy, text }
  end

  def test_the_vercel_deploy_keeps_its_safety_rules
    refute_includes deploy_stops, "tell the person the folder has no `.vercelignore`"
    ["you write no file named `.vercelignore`, anywhere", "You may propose its contents in chat only",
     "the person pushes it, or says to"].each { |text| assert_includes deploy_stops, text }
    ["Deploy anyway?", "exits 1 and builds nothing", "only once they confirm after seeing them all"].each { |text| assert_includes deploy_anyway, text }
    refute_includes deploy, "on Vercel as on Fly"
  end

  def test_it_passes_yes_only_after_the_person_confirms_the_open_items
    ["Not deployed.", "cadre deploy <repo> --yes", "only once they confirm", %q{tick it as "Tick a Before deploying item" says}].each do |text|
      assert_includes deploy_anyway, text
    end
    assert_operator deploy_anyway.index("Not deployed."), :<, deploy_anyway.index("--yes")
  end

  def test_it_confirms_a_blocked_deploy_before_passing_yes
    ["`#<n> is Blocked: <app> should run #<m> first.`", "`#<n> is Blocked: <app> should deploy first.`",
     "the release queue shows Blocked", "With `--app`, it lists only that app's items and Blocked PRs.",
     "say which PR is Blocked and what should go first, and propose deploying that first",
     "Run `cadre deploy <repo> --yes` only once they confirm after seeing them all, with the same `--app` or `--all`."].each do |text|
      assert_includes deploy_anyway, text
    end
    assert_operator deploy_anyway.index("is Blocked:"), :<, deploy_anyway.index("--yes")
  end

  def test_under_all_a_blocked_pr_the_run_clears_is_said_to_be_cleared
    assert_includes deploy_anyway,
                    "Under `--all`, when what should go first is an app the same run deploys first, say so: the run already deploys it first."
  end

  def test_it_checks_the_fly_config_name_before_setting_it
    ["isn't in this checkout", "Neither fly.production.toml nor fly.toml is in this checkout.", "--fly-config <file>",
     "Check the file's name with the person before setting it"].each { |text| assert_includes deploy_stops, text }
  end

  def test_setting_an_app_from_a_deploy_carries_its_settings_over
    pointer = %q{A fix below that runs `cadre repo set` sets the app again: read "Set an app again" in [connect.md](connect.md) first and carry every setting over.}
    assert_equal 1, deploy.scan(%q{"Set an app again"}).size
    assert_includes deploy_stops, pointer
    rerun = "Once a fix is made, deploy again when the person confirms: `cadre deploy <repo>` with the flags the fix leaves, the same `--app` or `--all` unless the fix chose another app. On Vercel, it builds and promotes again the apps that run deploys: the one `--app` names, or every app with `--all`."
    assert_includes deploy_stops, rerun
    refute_includes deploy, "builds and promotes every app again"
    assert_equal 1, deploy_stops.scan(/deploy again/i).size - deploy_stops.scan("then deploy again.`").size
  end

  def test_it_relays_a_deploy_of_an_app_with_no_fly_app
    ["<name> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app> --name <name>.",
     "<repo> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app>.",
     "<repo> has no app cadre can deploy."].each { |text| assert_includes deploy_stops, text }
  end

  def open_deploy_section = section(deploy, "## Open Deploy in the right folder")

  def test_it_explains_where_the_deploy_button_opens_and_links_only_when_asked
    ["`cadre link`", "opens Claude Desktop in the folder the person linked", "the folder it used last", "the prompt's last line names the repo",
     "Run it only when the person asks"].each { |text| assert_includes open_deploy_section, text }
    ["even from a linked worktree or a subfolder", "running it again replaces it"].each { |text| refute_includes deploy, text }
    refute_includes deploy, "## What a deploy does"
    assert_operator deploy.index("## Open Deploy in the right folder"), :<, deploy.index("## When a deploy stops")
  end

  def test_it_relays_cadre_links_own_answers
    no_table = refusal(open_deploy_section, "No Skills table in <path>/AGENTS.md. Setup shows how to write one: <url>/setup?part=skills`")
    ["the link is made", %q{offer to draft one, as "No Skills table" in [skills.md](skills.md) says}].each { |text| assert_includes no_table, text }
    ["Linked <repo> to <path>.", "A project names a repo before cadre knows it."].each { |text| refute_includes deploy, text }
    assert_includes refusal(open_deploy_section, "This folder isn't a checkout with an origin. Run cadre link in one.`"),
                    "ask the person where their checkout of the repo is, and run it there"
    refute_includes deploy, "cadre doesn't know <owner/name>. …"
  end

  def test_it_links_only_when_the_person_asks
    assert_includes open_deploy_section, "Run it only when the person asks."
    refute_match(/offer to (run|link)/, open_deploy_section)
  end

  def test_a_deploy_outside_the_repos_checkout_asks_for_a_new_session_there
    wrong_folder = section(deploy, "## When a deploy stops")[/^Wrong folder:\n\n(.*?)(?=\n\n\S)/m, 1] or flunk("no Wrong folder: lead-in")
    line = refusal(wrong_folder, "This folder isn't a checkout of <owner/repo>. Run cadre deploy in one.")
    ["the session runs outside that repo's checkout", "start a new session and pick their checkout of it as its folder",
     "there they run `cadre link` once, or ask you to", "the Deploy button opens in it from then on"].each { |text| assert_includes line, text }
  end

  def test_the_router_sends_cadre_link_to_deploy_md
    assert_includes router.lines.find { |line| line.include?("[deploy.md]") },
                    "remember where a repo's checkout is for cadre's Deploy button (`cadre link`)"
  end

  def test_it_ticks_a_before_deploying_item_only_once_told_it_is_done
    ["gh pr view <pr-url> --json body -q .body", "`- [ ]` to `- [x]`", "gh pr edit <pr-url> --body-file <file>",
     "reads Held", "When the person says an item is done, or you have just done it at their request:", "Items are ticked in GitHub",
     "In that repo's checkout, `gh pr view <number>` works with the number alone; from anywhere, pass its URL or `--repo <owner>/<repo>`.",
     "When the person's words match more than one item, ask which."].each { |text| assert_includes tick_section, text }
    refute_includes deploy, "Tick only what"
  end

  # Every skill file.

  def test_no_skill_file_names_colette
    skill_files.each { |path| refute_match(/colette/i, File.read(path), path) }
  end

  def test_skill_files_call_only_superpowers_skills_and_cadre_itself
    # cadre:brainstorming and cadre:writing-plans are cadre's own skills, which "Create a project" and
    # "Start a milestone" call (EP-I3).
    calls = skill_files.flat_map { |path| File.read(path).scan(/`([a-z][a-z0-9-]*:[a-z][a-z0-9-]*)`/).flatten }
    assert_equal %w[cadre:brainstorming cadre:cadre cadre:pr-description cadre:writing-plans superpowers:brainstorming superpowers:using-git-worktrees superpowers:writing-plans], calls.uniq.sort
    skill_files.each { |path| refute_match(/\bEP-[A-Z]\d/, File.read(path), path) }
  end

  def test_no_skill_file_pushes_or_commits_everything
    # the person runs the tag push, never the agent (EP-I3). The one push an agent makes is a PR's pictures, to an
    # assets branch of their own, never to the PR's branch: GitHub has no API that attaches an image to a description.
    assets_push = 'git push origin "${sha}:refs/heads/assets/pr-<n>"'
    skill_files.each do |path|
      text = File.read(path)
      text = text.sub(assets_push, "") if path.end_with?("pr-description/SKILL.md")
      refute_match(/git (push(?! origin <tag>`)|commit -a|add (\.|-A))/, text, path)
    end
  end
end

class PrDescriptionTest < Minitest::Test
  SKILL_PATH = File.join(PLUGIN, "skills", "pr-description", "SKILL.md")

  def skill = File.read(SKILL_PATH)
  def frontmatter = skill[/\A---\n(.*?)\n---\n/m, 1]
  include Sections

  def parts = section(skill, "## The parts")
  def part(number) = parts[/^#{number}\. (.*?)(?=^\d\. |^The check judges|\z)/m, 1] || flunk("no part #{number}")

  def test_frontmatter_names_the_skill_and_when_to_use_it
    assert_equal %w[description name], frontmatter.scan(/^([a-z-]+):/).flatten.sort
    assert_includes frontmatter, "name: pr-description"
    assert_includes frontmatter, "description: The standard for a pull request's title and description. Use when writing, checking or rewriting a PR title or description."
  end

  def test_it_says_what_the_standard_is_for_without_naming_other_plugins
    opening = skill[/^# PR description\n\n(.*?)\n\n## /m, 1]
    assert_includes opening, "whoever writes a PR follows it, and a reviewer checks every PR against it"
    ["engineering-principles", "review-companion"].each { |text| refute_includes opening, text }
  end

  def test_its_sections_and_parts_come_in_order
    headings = ["## The title", "## The parts", "## Template", "## Not essential", "## Marked spots", "## Pictures", "## Rewriting a description", "## A repository's own template"]
    outside_fences = skill.gsub(/^````markdown\n.*?^````\n/m, "")
    assert_equal headings, outside_fences.scan(/^## .*$/)
    names = ["What it does.", "Before deploying,", "How it works,", "Behind the scenes.", "Screenshots and videos,", "Break checks,", "The Cadre line,"]
    assert_equal names.each_with_index.map { |name, i| "#{i + 1}. **#{name}**" }, parts.scan(/^\d\. \*\*[^*]+\*\*/)
  end

  def test_the_title_gives_the_feature_and_its_place_in_a_sequence
    title = section(skill, "## The title")
    ["in a sequence: `<feature> (<i>/<n>): <what it delivers>`", "otherwise: `<feature>: <what it delivers>`",
     "the change edits a spec's `### Increment` status line;", "the description links a spec that has an `## Increments` section;",
     "the description says it is one step of a sequence", "the title already claims a place.",
     "A title whose number disagrees with the spec gives the wrong place."].each { |text| assert_includes title, text }
  end

  def test_the_title_example_is_a_feature_and_its_place
    assert_includes section(skill, "## The title"), "for example `Wish reminders (2/3): members choose when they are reminded`"
  end

  def test_behind_the_scenes_states_its_rules_in_words
    behind = part(4)
    ["the frontends and apps that depend on the change, whether each must change to keep working, and the order they deploy in — or that none must change.", "This line is always there",
     "A contract other apps use changes by adding the new first, moving every consumer, and removing the old only once no deployed consumer uses it, installed mobile app versions included",
     "The line also shows the change meets three conditions: it works while the previous version still runs during the rollout, with every column the previous version reads or writes still in place; what is unfinished is out of users' reach; and a rollback loses no data.",
     "the reason for each check the change turns off or weakens: a disabled lint, a new ignore, skip or baseline entry, a skipped test, a loosened threshold, or a pre-commit or CI step removed or made non-blocking."].each { |text| assert_includes behind, text }
    refute_includes skill, "elixir #"
    refute_includes skill, "never loosened"
  end

  def test_the_cadre_line_links_a_pull_request_and_names_its_app
    cadre_line = part(7)
    ["a line of its own that reads exactly `Cadre: <slug>/<n>`", "or `Cadre: <slug>/<n> <app>` for a pull request for one app",
     "Cadre reads this line and links the pull request to that milestone", "a PR without it shows as not linked",
     "The app is its name in Cadre, as `cadre repo show` lists it (a target's `name`): lowercase letters, digits, `-` or `_`.",
     "A line whose app isn't such a name links nothing.",
     "A spec that names only its project `<slug>` maps its increment to a milestone as \"Track a milestone's implementation\" in the `cadre:cadre` skill says.",
     "A PR that Cadre does not track has no such line."].each { |text| assert_includes cadre_line, text }
    ["Follow the `cadre:cadre` skill", "milestone `<slug>/<i>`"].each { |text| refute_includes cadre_line, text }
  end

  def test_before_deploying_holds_what_a_deploy_needs_first_and_how_items_are_ticked
    before = part(2)
    ["A heading line that reads exactly `## Before deploying`, then one `- [ ]` item for each", "env var or secret", "another repo to deploy first", "a manual step",
     "Cadre reads this section by name and shows the pull request as held until its items are ticked", "A change that needs nothing has no section.",
     %q{Its items are ticked as "Tick a Before deploying item" in the `cadre:cadre` skill says.}].each { |text| assert_includes before, text }
    assert_includes parts, "`## Before deploying` is the exception: its heading is exact."
    assert_includes section(skill, "## A repository's own template"), "It still holds `## Before deploying` as its own section, under that heading, and the Cadre line on a line of its own."
  end

  def test_a_draft_is_done_only_when_every_part_is_there_and_nothing_is_invented
    assert_includes parts, %q{A draft is done when each part is there or left out by its own "only when", and every fact the writer does not know is a marked spot.}
    marked = section(skill, "## Marked spots")
    ["It is never invented.", "`> **Picture to add:** <screen> — <state>, <before | after>`", "`> **Video to add:** <flow>`",
     "`> **Break checks to add:** <runner> --table`"].each { |text| assert_includes marked, text }
  end

  def test_pictures_are_captured_hosted_embedded_and_cleaned_up
    pictures = section(skill, "## Pictures")
    ["1. **Capture**", "2. **Host**", "3. **Embed**", "4. **Clean up**", "The braces in `${sha}` matter: zsh reads `$sha:r` as a modifier.",
     "never by the branch name"].each { |text| assert_includes pictures, text }
  end

  def test_a_rewrite_keeps_what_is_already_there
    rewrite = section(skill, "## Rewriting a description")
    ["keeps every image and video link already in the description",
     "keeps every `## Before deploying` item and its tick as it is, so a redraft never reopens a ticked one",
     "keeps the Break checks table byte for byte beyond part 6's dropped rows",
     "ends with the Cadre line when the PR's milestone is tracked in Cadre, keeping the line already there",
     "drops every instruction aimed at a reviewer or an AI", "never invented"].each { |text| assert_includes rewrite, text }
  end

  def test_a_table_with_no_row_of_this_change_is_not_done
    assert_includes part(6), "When no row is left, the break checks are not done"
  end

  def test_break_checks_say_which_rows_belong_to_the_change_without_another_skill
    break_checks = part(6)
    [
     "In the runner's table, each row has a Branch (`<file>:<line>`), a Swap (`` `<from>` → `<to>` ``) and the tests that caught it.",
     "A row belongs to this change when its Branch is in a file the change touches and its `<from>` spans a line the change adds or changes there, or sits on the line just above or below a line it deletes.",
     "the `break-check` skill, for a repo whose Skills table lists it"].each { |text| assert_includes break_checks, text }
    ["(`break-check`)", "as `break-check` defines it"].each { |text| refute_includes break_checks, text }
    template = skill[/^## Template\n(.*?)^## Not essential\n/m, 1]
    assert_includes template, "<The output of `<runner> --table`, its `<details>` block as the runner prints it.>"
  end

  def test_the_template_holds_the_parts_cadre_reads_by_name
    template = skill[/^## Template\n(.*?)^## Not essential\n/m, 1]
    ["\n## Before deploying\n\n- [ ] ", "\n\nCadre: <slug>/<n>\n````\n",
     "- Consumers: <each frontend and app, whether it must change, and the order they deploy in, or \"none\">",
     "- Deploy: <the order when this change goes first or that it doesn't matter, what stays behind a flag, what comes after the deploy, and that the change works while the previous version runs, keeps unfinished work out of users' reach and loses no data on rollback>"].each { |text| assert_includes template, text }
  end
end

class DesignLinkTest < Minitest::Test
  SCRIPT = File.join(PLUGIN, "skills", "cadre", "design_link.rb")
  CANVAS = "https://claude.ai/artifact/2Ut2UwnSnjEp9muwtAwqBJ"

  def link(*args) = Open3.capture2e("ruby", SCRIPT, *args)

  # The canvas wrote this fragment to its own address bar on the page "by-milestone".
  def test_it_links_a_page_by_its_id
    output, status = link(CANVAS, "--page", "by-milestone")
    assert status.success?, output
    assert_equal "#{CANVAS}#page-ed068eefbbfd\n", output
  end

  # This fragment opened the canvas framed on board M3.
  def test_it_links_a_board_by_its_file
    output, status = link(CANVAS, "--board", "M3.dc.html")
    assert status.success?, output
    assert_equal "#{CANVAS}#artboard-b02440b1710a\n", output
  end

  def test_it_replaces_the_fragment_a_link_already_has
    output, = link("#{CANVAS}#page-ed068eefbbfd", "--board", "M3.dc.html")
    assert_equal "#{CANVAS}#artboard-b02440b1710a\n", output
  end

  def test_it_shows_its_usage_when_called_any_other_way
    [[], [CANVAS], [CANVAS, "--page"], [CANVAS, "--page", ""], [CANVAS, "--frame", "M3"], ["http://claude.ai/artifact/a", "--page", "p"]].each do |args|
      output, status = link(*args)
      refute status.success?, args.inspect
      assert_includes output, "Usage: ruby design_link.rb"
    end
  end
end

class SkillsTableTest < Minitest::Test
  SCRIPT = File.join(PLUGIN, "skills", "cadre", "skills_table.rb")
  HEADER = "| Skill | When | Install |\n| --- | --- | --- |\n"
  COMMITTED = "committed in `.agents/skills/`"

  def setup = @dir = Dir.mktmpdir
  def teardown = FileUtils.remove_entry(@dir)

  # A repo in a temporary folder: AGENTS.md, CLAUDE.md, skills committed with a
  # SKILL.md, bare folders without one, and entries in .claude/skills (a link
  # target, or :folder for a real folder).
  def repo(agents_md:, claude_md: "@AGENTS.md\n", committed: [], folders: [], links: {})
    File.write(File.join(@dir, "AGENTS.md"), agents_md) if agents_md
    File.write(File.join(@dir, "CLAUDE.md"), claude_md) if claude_md
    committed.each do |name|
      FileUtils.mkdir_p(File.join(@dir, ".agents", "skills", name))
      File.write(File.join(@dir, ".agents", "skills", name, "SKILL.md"), "---\nname: #{name}\n---\n")
    end
    folders.each { |name| FileUtils.mkdir_p(File.join(@dir, ".agents", "skills", name)) }
    FileUtils.mkdir_p(File.join(@dir, ".claude", "skills"))
    links.each do |name, target|
      path = File.join(@dir, ".claude", "skills", name)
      target == :folder ? FileUtils.mkdir_p(path) : File.symlink(target, path)
    end
    @dir
  end

  def table(rows) = "# repo\n\n## Skills\n\n#{HEADER}#{rows.map { |row| "| #{row.join(' | ')} |\n" }.join}\nLoad each skill.\n"
  def link_to(name) = "../../.agents/skills/#{name}"

  def read(dir, env = {})
    output, status = Open3.capture2e(env, "ruby", SCRIPT, dir)
    assert status.success?, output
    JSON.parse(output.force_encoding("UTF-8"))
  end

  def problems(result) = result["rows"].to_h { |row| [row["skill"], row["problems"]] }

  # An agent's shell may run with no locale, where Ruby reads files as US-ASCII.
  def test_it_reads_a_row_with_non_ascii_text_without_a_locale
    dir = repo(agents_md: table([["plugin:skill", "any LiveView — HEEx", "claude plugin install plugin@market"]]))

    assert_equal "any LiveView — HEEx", read(dir, { "LANG" => "C", "LC_ALL" => "C" })["rows"].first["when"]
  end

  def test_it_finds_the_heading_with_trailing_spaces
    dir = repo(agents_md: table([["plugin:skill", "work", "claude plugin install plugin@market"]]).sub("## Skills\n", "## Skills  \n"))

    assert_equal ["plugin:skill"], read(dir)["rows"].map { |row| row["skill"] }
  end

  def test_it_reads_no_table_when_the_header_has_no_separator_line
    dir = repo(agents_md: "## Skills\n\n| Skill | When | Install |\n| plugin:skill | work | claude plugin install plugin@market |\n")

    assert_equal false, read(dir)["table"]
  end

  def test_it_skips_an_example_table_in_a_code_block
    example = "```markdown\n#{HEADER}| `<skill>` | <when> | committed in `.agents/skills/` |\n```\n\n"
    dir = repo(agents_md: table([["plugin:skill", "work", "claude plugin install plugin@market"]]).sub("## Skills\n\n", "## Skills\n\n#{example}"))

    assert_equal ["plugin:skill"], read(dir)["rows"].map { |row| row["skill"] }
  end

  def test_it_reads_each_row_and_passes_a_committed_skill_with_its_folder_and_link
    dir = repo(agents_md: table([["`flutter-expert`", "widgets", COMMITTED],
                                 ["`plugin:skill`", "any code", "`claude plugin install plugin@market`"]]),
               committed: ["flutter-expert"], links: { "flutter-expert" => link_to("flutter-expert") })

    result = read(dir)

    assert_equal true, result["table"]
    assert_equal [{ "skill" => "flutter-expert", "when" => "widgets", "install" => "committed in .agents/skills/", "committed" => true, "problems" => [] },
                  { "skill" => "plugin:skill", "when" => "any code", "install" => "claude plugin install plugin@market", "committed" => false, "problems" => [] }],
                 result["rows"]
    assert_equal [], result["unlisted"]
  end

  def test_it_names_what_a_committed_row_lacks
    names = %w[gone bare unlinked absolute crossed copied]
    dir = repo(agents_md: table(names.map { |name| [name, "work", COMMITTED] }),
               committed: %w[unlinked absolute crossed copied], folders: ["bare"],
               links: { "bare" => link_to("bare"), "absolute" => File.join(@dir, ".agents", "skills", "absolute"),
                        "crossed" => link_to("copied"), "copied" => :folder })

    assert_equal({ "gone" => ["no folder .agents/skills/gone", ".claude/skills/gone does not link to ../../.agents/skills/gone"],
                   "bare" => ["no SKILL.md in .agents/skills/bare"],
                   "unlinked" => [".claude/skills/unlinked does not link to ../../.agents/skills/unlinked"],
                   "absolute" => [".claude/skills/absolute does not link to ../../.agents/skills/absolute"],
                   "crossed" => [".claude/skills/crossed does not link to ../../.agents/skills/crossed"],
                   "copied" => [".claude/skills/copied does not link to ../../.agents/skills/copied"] },
                 problems(read(dir)))
  end

  def test_it_flags_a_plugin_row_without_an_install_command
    dir = repo(agents_md: table([["plugin:skill", "work", "see the wiki"]]))

    assert_equal({ "plugin:skill" => ["Install is neither committed in .agents/skills/ nor claude plugin install <plugin>@<marketplace>"] },
                 problems(read(dir)))
  end

  def test_it_keeps_an_escaped_pipe_inside_a_cell
    dir = repo(agents_md: table([["plugin:skill", "`a \\| b`", "claude plugin install plugin@market"]]))

    assert_equal "a | b", read(dir)["rows"].first["when"]
  end

  def test_it_reports_folders_no_row_lists
    dir = repo(agents_md: table([["kept", "work", COMMITTED]]), committed: %w[kept stray], links: { "kept" => link_to("kept") })

    assert_equal ["stray"], read(dir)["unlisted"]
  end

  def test_it_reads_no_table_when_there_is_none
    [nil, "# repo\n\n## Skills\n\nNone yet.\n", "# repo\n\n## Skills\n\nSoon.\n\n## Other\n\n#{HEADER}| a | b | c |\n"].each do |agents_md|
      FileUtils.rm_f(File.join(@dir, "AGENTS.md"))
      result = read(repo(agents_md: agents_md, committed: ["stray"]))

      assert_equal false, result["table"], agents_md.inspect
      assert_equal [], result["rows"]
      assert_equal ["stray"], result["unlisted"]
    end
  end

  def test_it_says_whether_claude_md_imports_agents_md
    { "# Repo\n\n@AGENTS.md\n" => true, nil => false, "# Repo\n\nsee @AGENTS.md\n" => false }.each do |claude_md, imports|
      FileUtils.rm_f(File.join(@dir, "CLAUDE.md"))

      assert_equal imports, read(repo(agents_md: table([]), claude_md: claude_md))["imports_agents_md"], claude_md.inspect
    end
  end

  def test_it_shows_its_usage_when_called_any_other_way
    file = File.join(@dir, "AGENTS.md")
    File.write(file, "")
    [[], [@dir, @dir], [file]].each do |args|
      output, status = Open3.capture2e("ruby", SCRIPT, *args)

      refute status.success?, args.inspect
      assert_includes output, "Usage: ruby skills_table.rb"
    end
  end
end

class BrainstormingTest < Minitest::Test
  def skill = File.read(File.join(PLUGIN, "skills", "brainstorming", "SKILL.md"))
  def frontmatter = skill[/\A---\n(.*?)\n---\n/m, 1]
  include Sections

  def before_you_start = section(skill, "## Before you start")

  def test_frontmatter_names_the_skill_and_when_it_runs
    assert_equal %w[description name], frontmatter.scan(/^([a-z-]+):/).flatten.sort
    assert_includes frontmatter, "name: brainstorming"
    assert_includes frontmatter, %q{description: Cadre brainstorming, which ends with the feature registered as a Cadre project. Use only when the person names it ("cadre:brainstorming", "cadre's brainstorming"), or when the cadre skill calls it from "Create a project".}
  end

  def test_brainstorm_names_apps
    assert_includes skill, "apps of a repo that has several"
  end

  def test_the_opening_says_what_the_brainstorm_ends_as_and_leaves_the_rest_to_the_handoff
    assert_equal "You brainstorm the feature with the person through `superpowers:brainstorming`, and it ends as a feature spec: an end goal and the milestones that reach it.\n\n",
                 skill[/^# Cadre brainstorming\n\n(.*?)(?=^## )/m, 1]
  end

  def test_the_checks_come_before_the_brainstorm
    assert_equal ["## Before you start", "## Run superpowers brainstorming", "## What a milestone is", "## Drafting the milestones",
                  "## The feature spec", "## The handoff"], skill.gsub(/^```.*?^```$/m, "").scan(/^## .*$/)
  end

  def test_it_stops_when_superpowers_brainstorming_is_missing
    ["`superpowers:brainstorming`", "`superpowers` plugin", "`claude-plugins-official`", "and stop"].each { |text| assert_includes before_you_start, text }
  end

  def test_it_checks_the_cli_and_the_sign_in_before_it_brainstorms
    ["Run only", "[the cadre skill](../cadre/SKILL.md)", %q{"Before you start"}, %q{"Install or update the CLI"},
     %q{"Sign in"}, %q{in [the cadre skill](../cadre/SKILL.md), then come back here. When one of those sections says to stop, the brainstorm stops too.},
     %q{The cadre skill's rules for a command's flags and for a refusal no file names, at the end of its "What to read next", hold for the rest of this run.},
     %q{This step is done once "Sign in" ends with the person signed in.}].each { |text| assert_includes before_you_start, text }
    refute_includes before_you_start, "in that order"
    refute_includes before_you_start, "holds an `email`"
    assert_operator before_you_start.index("`superpowers:brainstorming`"), :<, before_you_start.index("[the cadre skill]")
  end

  def test_it_stops_on_a_superpowers_older_than_7
    run = section(skill, "## Run superpowers brainstorming")
    ["no builder check", "older than 7.0", "update the `superpowers` plugin", "and stop"].each { |text| assert_includes run, text }
    assert_operator run.index("no builder check"), :<, run.index("follow it as written")
  end

  def test_it_runs_superpowers_brainstorming_as_written_with_cadres_rules_on_top
    [%q{Invoke `superpowers:brainstorming` with the person's request, and with the spec the person or "Create a project" names, when there is one.},
     "follow it as written", %q{Invoke it directly from this skill, so "The handoff" below runs.},
     "Where they differ from it, they win"].each { |text| assert_includes skill, text }
    refute_includes skill, "wraps it"
  end

  def test_it_leaves_the_conversation_to_superpowers
    ["wishing this existed", "one open question", "several approaches", "200–300 words"].each { |text| refute_includes skill, text }
  end

  def test_its_rules_cover_what_superpowers_does_not
    ["even when it fits in one milestone", "the repos it touches", "must deploy first", "apps that use what changes",
     "without asking", "Ask before reading anything outside it", "Play the milestones back"].each { |text| assert_includes skill, text }
  end

  def test_a_milestone_is_the_smallest_step_that_ships_one_feature_and_deploys_alone
    ["one feature", "smallest step", "previous version still runs", "out of users' reach", "a rollback loses no data",
     "installed mobile app versions", "deploy order", "never on a later one", "aim for 10", "20 code files",
     "two smaller", "never invent a split"].each { |text| assert_includes skill, text }
  end

  def test_a_milestone_is_a_vertical_slice_and_contracts_change_by_expand_contract
    ["a *vertical slice*", "thin and end to end", "by *expand–contract*: add the new, move every consumer"].each { |text| assert_includes skill, text }
    assert_equal 1, skill.scan("out of users' reach").size
  end

  def test_a_large_milestone_says_why_on_its_code_files_line
    assert_includes skill, "its **Code files** line says why it can't be smaller"
    ["This is a preference, not a limit", "Don't ask the person this"].each { |text| refute_includes skill, text }
  end

  def test_skipping_the_questions_leaves_one_approval_before_the_commit
    skip_path = skill[/When the person says to skip the questions(.*?)$/, 1]
    ["still ends with the spec", "mark every open point as your call", "approve the spec"].each { |text| assert_includes skip_path, text }
  end

  def test_the_feature_spec_has_cadres_tracking_line_under_its_title
    ["the line under it that says it is tracked in Cadre", "step 3 of \"Create a project\" in [project.md](../cadre/project.md)", "kebab case"].each { |text| assert_includes skill, text }
  end

  def test_it_commits_only_the_spec_file
    assert_includes skill, 'git commit -m "docs: <feature> design" -- <path>'
  end

  def test_it_hands_back_to_the_cadre_skill_instead_of_writing_plans
    assert_includes skill, "instead of invoking `superpowers:writing-plans`"
    handoff = section(skill, "## The handoff")
    assert_includes handoff, %q{follow "Create a project" in [project.md](../cadre/project.md) from step 2, with that spec.}
    refute_includes handoff, "scripts"
  end

  def test_the_split_challenge_keeps_each_part_usable
    assert_includes skill, "two smaller ones that each deploy and give someone something to use"
  end

  def test_it_writes_and_commits_the_feature_spec
    ["docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md", "`-2`", "## End goal", "## Increments", "### Increment <i> — ",
     "**Delivers:**", "**Deployable alone:**", "**Consumers:**", "**Code files:**",
     "plans increment 1", "Once the person approves the spec", "commit only the spec file", "leave the push to the person"].each { |text| assert_includes skill, text }
    refute_includes skill, "Not shipped"
  end
end

class WritingPlansTest < Minitest::Test
  PLAN_LINE = SkillTest::PLAN_LINE

  def skill = File.read(File.join(PLUGIN, "skills", "writing-plans", "SKILL.md"))
  def frontmatter = skill[/\A---\n(.*?)\n---\n/m, 1]
  include Sections

  def before_you_start = section(skill, "## Before you start")
  def what_to_plan = section(skill, "## What to plan")
  def milestone_section = section(skill, "## A Cadre milestone")
  def run_section = section(skill, "## Run superpowers writing-plans")
  def one_pull_request = section(skill, "## One pull request")

  def test_frontmatter_names_the_skill_and_when_it_runs
    assert_equal %w[description name], frontmatter.scan(/^([a-z-]+):/).flatten.sort
    assert_includes frontmatter, "name: writing-plans"
    assert_includes frontmatter, %q{description: Cadre planning, which plans one pull request at a time for a Cadre milestone or for requirements. Use only when the person names it ("cadre:writing-plans", "cadre's planning"), or when the cadre skill calls it from "Start a milestone".}
  end

  def test_the_opening_says_it_plans_one_pull_request_at_a_time
    assert_equal "You plan one pull request at a time through `superpowers:writing-plans`: one repo's part of a Cadre milestone, or requirements given with no spec. Later milestones are planned once this one has shipped, with what it taught.\n\n",
                 skill[/^# Cadre writing plans\n\n(.*?)(?=^## )/m, 1]
  end

  def test_its_sections_come_in_order
    assert_equal ["## Before you start", "## What to plan", "## A Cadre milestone", "## One pull request", "## Run superpowers writing-plans"],
                 skill.gsub(/^ *```.*?^ *```$/m, "").scan(/^## .*$/)
  end

  def test_it_stops_when_superpowers_writing_plans_is_missing
    ["`superpowers:writing-plans`", "`superpowers` plugin", "`claude-plugins-official`", "and stop"].each { |text| assert_includes before_you_start, text }
  end

  def test_it_says_what_it_chose_and_why
    assert_includes before_you_start, %q{Find what to plan, as "What to plan" says, and tell the person what you chose and why.}
  end

  def test_it_checks_the_cli_and_the_sign_in_for_cadre_work
    [%q{For "A Cadre milestone" and "A spec not tracked in Cadre", run only "Before you start", "Install or update the CLI" and "Sign in" in [the cadre skill](../cadre/SKILL.md), then come back here. When one of those sections says to stop, the planning stops too.},
     %q{This step is done once "Sign in" ends with the person signed in.},
     %q{The cadre skill's rules for a command's flags and for a refusal no file names, at the end of its "What to read next", hold for the rest of this run.}].each { |text| assert_includes before_you_start, text }
    assert_operator before_you_start.index("`superpowers:writing-plans`"), :<, before_you_start.index("[the cadre skill]")
  end

  def test_what_to_plan_takes_the_first_case_that_fits
    ["Take the first case that fits", "**Handed over:**", %q{step 5 of "Start a milestone" in [milestone.md](../cadre/milestone.md) handed you its spec copy's path},
     %q{go to step 3 of "A Cadre milestone"}, "**A Cadre milestone:**", "`<slug>/<n>`", "a Cadre project",
     "a spec whose line under its title says it is tracked in Cadre", "**A spec not tracked in Cadre:**",
     "**Requirements with no spec:**", "describes a feature or a change", "ask the person what to plan: a milestone, a spec or requirements",
     "follow the section named for the case"].each { |text| assert_includes what_to_plan, text }
    assert_operator what_to_plan.index("**Handed over:**"), :<, what_to_plan.index("**A Cadre milestone:**")
  end

  def test_it_finds_the_milestone_to_plan
    ["its increment `<i>` is milestone `<slug>/<i>`", "whose `current` is true in `cadre status <slug> --json`", "and say so",
     "ask the person which"].each { |text| assert_includes milestone_section, text }
  end

  def test_named_for_a_milestone_it_runs_start_a_milestone_first
    [%q{Run only steps 1 to 4 of "Start a milestone" in [milestone.md](../cadre/milestone.md) for `<slug>/<n>`, then come back here. When one of those steps says to stop, the planning stops too.},
     "This step is done when you hold the spec copy's path, this repo's part and, for one app's pull request, its app, on the milestone's branch."].each do |text|
      assert_includes milestone_section, text
    end
  end

  def test_the_plan_says_it_is_tracked_in_cadre
    assert_includes milestone_section, PLAN_LINE
    ["so whoever executes it uses the `cadre:cadre` skill", "For one app's plan, the line ends with ` <app>`: `Cadre: <slug>/<n> <app>`.",
     %q{only this repo's part of `<slug>/<n>`, or the app "Start a milestone" chose}].each { |text| assert_includes milestone_section, text }
    assert_equal 1, skill.scan("REQUIRED SKILL").size
    refute_includes skill, "this skill's folder"
  end

  def test_it_reads_the_skills_table_before_planning
    assert_includes run_section, "Read the repo's Skills table, check its rows and load the skills the work calls for, as [skills.md](../cadre/skills.md) says."
    assert_operator run_section.index("[skills.md]"), :<, run_section.index("Invoke `superpowers:writing-plans`")
  end

  def test_it_runs_superpowers_writing_plans_with_cadres_rules_on_top
    ["Invoke `superpowers:writing-plans` with the spec copy's path or the requirements, and these rules on top. Where they differ from it, they win:",
     "Plan only the part this skill chose, as one plan and one pull request: the spec-coverage check covers that part alone.",
     "Each task names the skills it needs (from the table when the repo has one), since a subagent executing it loads only those."].each { |text| assert_includes run_section, text }
  end

  def test_the_plan_pushes_and_opens_its_pull_request
    ["The plan ends with a pull request task, which names `cadre:pr-description` among the skills it loads: it holds the rules for the title, the `Cadre:` line and the `## Before deploying` section.",
     "It pushes the branch and opens the pull request, never a local merge."].each { |text| assert_includes run_section, text }
  end

  def test_later_review_rounds_review_only_the_new_commits
    ["When the final review runs in rounds", "The first round reviews the whole branch", "`git diff <last-reviewed-sha>..HEAD`",
     "lists every earlier ruling as a standing decision", "under the plan's final review task"].each { |text| assert_includes run_section, text }
  end

  def test_execution_stays_with_superpowers
    assert_includes run_section, "Execute the plan as `superpowers:writing-plans` offers."
  end
  
  def test_it_asks_before_planning_after_an_unmerged_milestone
    ["Run `cadre status <slug> --json`.", "lists the project's milestones in order, not by number",
     "When an entry before `<n>`'s has a `state` that is neither `can_deploy` nor `deployed`",
     "name it to the person and ask whether to plan anyway"].each { |text| assert_includes milestone_section, text }
  end
  
  def test_it_rechecks_the_milestone_against_the_code_as_it_is_now
    ["Read the code as it is now, without asking.", %q{as "One pull request" says, and estimate its code files},
     %q{update it as "Update a milestone's spec" in [project.md](../cadre/project.md) says},
     %q{pull and commit the spec copy again, as steps 1 and 4 of "Start a milestone" do}].each { |text| assert_includes milestone_section, text }
    assert_operator milestone_section.index("cadre status <slug> --json`."), :<, milestone_section.index("Read the code as it is now")
    assert_operator milestone_section.index("Read the code as it is now"), :<, milestone_section.index(%q{Plan as "Run superpowers writing-plans" says})
  end
  
  def test_one_pull_request_ships_one_milestone
    ["A plan is one pull request that ships one milestone: one feature, the smallest step that can be deployed and used on its own, and its consumers named",
     %q{as "What a milestone is" in [the brainstorming skill](../brainstorming/SKILL.md) defines them. Read only that section there.},
     "Its code files are counted without tests and docs: aim for 10, and prefer 20 or fewer."].each { |text| assert_includes one_pull_request, text }
  end
  
  def test_a_plan_above_20_code_files_says_why_or_stops
    [%q{When the plan's file structure holds more than 20 code files, counted as "One pull request" says, the plan says why it can't be smaller.},
     "When it could be smaller, stop before writing the plan",
     %q{propose the split of a milestone to the person, as "Change a project" in [project.md](../cadre/project.md) adds a milestone}].each { |text| assert_includes run_section, text }
  end
end
