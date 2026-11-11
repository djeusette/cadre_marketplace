require "minitest/autorun"
require "json"
require "open3"

ROOT =File.expand_path("../../..", __dir__)
PLUGIN = File.join(ROOT, "plugins", "cadre")
INSTALL = 'gh release download -R djeusette/cadre_cli --pattern "cadre_$(uname -s)_$(uname -m).tar.gz" -O - | tar -xz -C ~/.local/bin cadre'

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
    refute_includes readme, "needs no other plugin"
    refute_match(/colette/i, readme.sub("(https://colette-cadre.fly.dev)", ""))
  end

  def test_marketplace_is_cadre_and_links_its_repo
    assert_equal "cadre", marketplace["name"]
    assert_equal "https://github.com/djeusette/cadre_marketplace", manifest["repository"]
  end

  def test_marketplace_lists_cadre_last_at_the_plugin_version
    assert_equal "cadre", marketplace.fetch("plugins").last["name"]
    assert_equal "./plugins/cadre", entry["source"]
    assert_equal "0.26.0", manifest["version"]
    assert_equal manifest["version"], entry["version"]
  end

  def test_descriptions_match
    refute_empty manifest["description"]
    assert_equal manifest["description"], entry["description"]
  end

  def test_readme_lists_cadre
    assert_match(/^- \*\*cadre\*\* — /, File.read(File.join(ROOT, "README.md")))
  end

  def test_readme_says_it_starts_a_milestone_and_links_a_pull_request
    readme = File.read(File.join(ROOT, "README.md"))
    ["start milestone <project>/<n>", "cadre pr link"].each { |text| assert_includes readme, text }
  end

  def test_readme_says_it_connects_repos_and_fly_orgs
    readme = File.read(File.join(ROOT, "README.md"))
    ["cadre repo set", "cadre fly org add"].each { |text| assert_includes readme, text }
  end

  def test_readme_says_it_deploys_with_the_commit
    assert_includes File.read(File.join(ROOT, "README.md")), "cadre deploy"
  end

  def test_readme_says_a_repo_can_have_several_apps
    readme = File.read(File.join(ROOT, "README.md"))
    ["several apps", "`--app`", "`--all`", "`cadre repo unset --name`"].each { |text| assert_includes readme, text }
  end

  def test_readme_says_its_specs_and_plans_are_tracked_in_cadre
    assert_includes File.read(File.join(ROOT, "README.md")), "say they are tracked in Cadre"
  end
end

class SkillTest < Minitest::Test
  FEATURE_LINE = %q{> Tracked in Cadre as `<slug>`. Implement each increment with the `cadre:cadre` skill ("start milestone <slug>/<i>"), which plans it and links its pull request to its milestone.}
  MILESTONE_LINE = %q{> Tracked in Cadre as `<slug>/<n>`. Implement it with the `cadre:cadre` skill ("start milestone <slug>/<n>"), which plans it and links its pull request to the milestone.}
  PLAN_LINE = %q{> **Tracked in Cadre as `<slug>/<n>`.** REQUIRED SKILL: use `cadre:cadre` while implementing this plan. Its pull request's description has the line `Cadre: <slug>/<n>`.}
  KEY_LINE = "Your key for <url> is no longer valid. Run cadre login --url <url>."
  SKILL_DIR = File.join(PLUGIN, "skills", "cadre")
  BRANCHES = %w[project.md milestone.md connect.md deploy.md]

  def read(name) = File.read(File.join(SKILL_DIR, name))
  def skill = read("SKILL.md")
  def project = read("project.md")
  def milestone = read("milestone.md")
  def connect = read("connect.md")
  def deploy = read("deploy.md")
  def everything = ["SKILL.md", *BRANCHES].map { |name| read(name) }.join("\n")
  def skill_files = Dir[File.join(PLUGIN, "skills", "**", "*")].select { |path| File.file?(path) }

  # The text under a heading, up to the next heading of the same level or above.
  def section(text, heading)
    level = heading[/\A#+/].length
    text[/^#{Regexp.escape(heading)}\n(.*?)(?=^\#{1,#{level}} |\z)/m, 1] or flunk("no section #{heading}")
  end

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
    ["create, change or drop a project or its milestones in Cadre", "read or update a milestone's spec",
     "start a milestone (\"start milestone <project>/<n>\")", "link a pull request to a milestone",
     "connect a repo to where it deploys or ask where it does", "connect a mobile app to its stores",
     "deploy a repo that runs on Fly or Vercel", "tick a Before deploying item",
     "implement a spec or plan that says it is tracked in Cadre", "sign in to Cadre"].each { |text| assert_includes description, text }
  end

  def router = section(skill, "## What to read next")

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
      deploy => ["# Deploy a repo", "## Tick a Before deploying item"] }.each do |text, headings|
      headings.each { |heading| assert_match(/^#{Regexp.escape(heading)}$/, text) }
    end
  end

  def install_section = section(skill, "## Install or update the CLI")

  def test_it_installs_a_missing_cli_and_upgrades_an_old_one
    assert_includes install_section, INSTALL
    ["When the command is missing,", "below `0.19.0`", "run `cadre upgrade`"].each { |text| assert_includes install_section, text }
    ["0.1.0", "below `0.18.0`", "below `0.17.0`", "below `0.16.0`", "below `0.15.0`", "below `0.14.0`", "below `0.13.0`", "below `0.12.0`", "below `0.11.0`", "below `0.2.0`", "below `0.3.0`", "below `0.4.0`", "below `0.5.0`", "below `0.6.0`", "below `0.7.0`", "below `0.8.0`"].each { |text| refute_includes everything, text }
  end

  def sign_in = section(skill, "## Sign in")

  def test_it_asks_the_person_for_the_cadre_url
    ["Ask the person for their Cadre URL", "The URL comes from the person alone", "cadre login --url <url>"].each { |text| assert_includes sign_in, text }
    refute_match(/colette-cadre\.fly\.dev|CADRE_URL/, everything)
    refute_match(/run `cadre login`(?! --url)/, everything)
  end

  def test_it_runs_the_login_in_the_background_and_relays_the_code
    ["run_in_background", "600000 ms", "Opening <uri> in your browser.", "Check that the page shows this code: <code>"].each { |text| assert_includes sign_in, text }
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

  def test_creating_a_project_brainstorms_through_brainstorm_md
    assert_includes create_section, "[brainstorm.md](brainstorm.md)"
    refute_match(/available skills|must be installed/, everything)
  end

  def test_it_builds_from_a_spec_the_person_names
    ["already has an `## End goal` and an `## Increments` section", "When a spec in `docs/superpowers/specs/` might be this feature, ask the person whether it is",
     "a spec is this feature's only once the person says so"].each { |text| assert_includes create_section, text }
  end

  def test_it_writes_a_spec_and_designs_for_every_milestone
    ["\"canvas_url\"", "\"design_url\"", "\"spec\""].each { |key| assert_includes example, key }
    ["one Claude Design canvas", "one page per milestone", "diagram", "share the canvas"].each { |text| assert_includes create_section, text }
  end

  def test_its_example_milestones_are_usable_slices_not_layers
    refute_includes example, "The API stores a reminder date"
    assert_includes example, "Members get a reminder before a wish expires"
  end

  def test_nothing_is_registered_before_the_person_approves
    assert_operator create_section.index("Register nothing until the person approves"), :<, create_section.index("cadre project create <file> --json")
  end

  def test_the_feature_spec_says_it_is_tracked_in_cadre
    [FEATURE_LINE, "Add the line when the spec lacks it"].each { |text| assert_includes create_section, text }
    assert_includes project_refusals, "change it on the spec's tracking line too"
  end

  def test_a_corrected_spec_is_committed_alone_or_left_to_the_person
    ['git commit -m "docs: <feature> design" -- <path>', "never push", "leave the commit to them"].each { |text| assert_includes create_section, text }
  end

  def test_it_reports_the_json_url_and_explains_zero_based_paths
    assert_includes create_section, "`url` field"
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
     "An app that isn't connected yet can be named", "A milestone lists a repo one way only: bare, or by its apps",
     "No repo <repo> on <server>.", "stays a bare `repo` unless the spec names its apps"].each do |text|
      assert_includes repos_section, text
    end
    assert_includes create_section, %q{its `repos` as "A milestone's `repos`" says}
    assert_includes change_section, %q{name their apps, as "A milestone's `repos`" says}
    assert_includes limits, "| `repos` | 1–10 per milestone, no repeats, each `repo` or `repo/app`"
  end

  def test_a_milestones_spec_says_it_is_tracked_in_cadre
    assert_includes write_section, MILESTONE_LINE
  end

  def test_it_links_each_milestone_to_its_own_page
    ["[design_link.rb](design_link.rb)", "--page <id>", "--board <file>", "project/canvas.json", "keeps the canvas link", "address bar"].each do |text|
      assert_includes design_section, text
    end
    [create_section, change_section].each { |text| assert_includes text, 'as "Link a milestone to its design" says' }
    assert_includes example, "https://claude.ai/artifact/…#page-…"
    ["?page=", "claude.ai/design/p/"].each { |text| refute_includes everything, text }
  end

  def test_it_pulls_a_spec_edits_it_and_pushes_it_with_its_base
    ["update the spec of", "cadre spec pull <project>/<n> -o <file> --json", "cadre spec push <project>/<n> <file> --json", "--base <version>",
     "has no spec yet.", "previous version", "pull again first"].each { |text| assert_includes update_section, text }
    ["changed since you pulled it. Pull it again.", "tell the person who (`updated_by`)", "No milestone <project>/<n> on <server>."].each do |text|
      assert_includes project_refusals, text
    end
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

  def test_a_new_milestone_gets_its_page_and_its_number_is_reported
    ["Draw its page in the project's design canvas", "`design_url`", "Report the new number"].each { |text| assert_includes change_section, text }
  end

  def test_an_unarchived_project_keeps_its_file
    assert_includes change_section, "continue with the same file: unarchiving doesn't change the version"
  end

  def test_limits_name_the_spec_and_link_rules
    ["100 000", "not blank", "https://", "2 000"].each { |text| assert_includes limits, text }
  end

  # milestone.md

  def start_section = section(milestone, "## Start a milestone")
  def track_section = section(milestone, "## Track a milestone's implementation")
  def link_section = section(milestone, "## Link a pull request by hand")
  def pr_description = section(milestone, "## The pull request's description")
  def first_step = section(milestone, "## The first step with no pull request")
  def milestone_refusals = section(milestone, "## When `cadre` refuses")

  def test_it_starts_a_milestone_with_one_plan_and_one_pull_request_per_repo
    ["cadre project pull", "cadre spec pull <slug>/<n>", "docs/superpowers/specs/<slug>-<n>.md", "`superpowers:writing-plans`",
     "Cadre: <slug>/<n>", "in its own session", "one plan and one pull request", "gh repo view --json name -q .name",
     %q{as "Update a milestone's spec" in [project.md](project.md) says}].each do |text|
      assert_includes start_section, text
    end
    ["No project <slug> on <server>.", "No milestone <slug>/<n> on <server>."].each { |text| assert_includes milestone_refusals, text }
  end

  def test_it_commits_only_the_spec_copy
    ["git add <path>", 'git commit -m "docs: spec of <slug>/<n>" -- <path>', "cadre reads only its own"].each { |text| assert_includes start_section, text }
  end

  def test_it_commits_the_spec_copy_on_the_milestones_branch_and_leaves_the_default_branch
    ["gh repo view --json defaultBranchRef -q .defaultBranchRef.name", "git switch -c <slug>-<n>", "git switch <slug>-<n>",
     "the default branch stays as it was"].each { |text| assert_includes start_section, text }
    assert_operator start_section.index("git switch -c <slug>-<n>"), :<, start_section.index("git add <path>")
  end

  def test_it_skips_the_commit_when_the_spec_copy_is_unchanged
    assert_includes start_section, "already holds this text, as when a milestone is started again, skip the commit"
  end

  def test_it_starts_a_milestone_from_its_app_steps
    ["a repo/app entry is its repo", "one plan and one pull request per repo, or per app", "the first step with no pull request",
     %q{found as "The first step with no pull request" says}, "the branch is `<slug>-<n>-<app>` instead",
     "the header's last line names it", "Its pull request's description has the line `Cadre: <slug>/<n> <app>`.\n     ```"].each { |text| assert_includes start_section, text }
    ["gh pr list --repo <owner>/<repo> --state all --search", "A closed, unmerged pull request holds nothing",
     "`gh repo view --json owner -q .owner.login`", "also matches `<slug>/20`", "names exactly `<slug>/<n>`, optionally followed by an app",
     "When the first step none holds is unclear, ask the person."].each { |text| assert_includes first_step, text }
  end

  def test_the_plan_says_it_is_tracked_in_cadre
    assert_includes start_section, PLAN_LINE
  end

  def test_the_cadre_line_links_a_pull_request_and_names_its_app
    ["reads exactly `Cadre: <slug>/<n>`", "`Cadre: <slug>/<n> <app>` for a pull request for one app", "A line of its own",
     "as `cadre repo show` lists it (a target's `name`)", "A line whose app isn't such a name links nothing"].each { |text| assert_includes pr_description, text }
  end

  def test_the_pull_request_lists_what_a_deploy_needs_first
    ["a heading line `## Before deploying`", "- [ ]", "env var", "another repo", "manual step", "A change that needs nothing has no section"].each do |text|
      assert_includes pr_description, text
    end
    assert_equal 1, everything.scan("a heading line `## Before deploying`").size
    assert_includes start_section, %q{the two rules of "The pull request's description", given in full: its `Cadre:` line and its `## Before deploying` section}
    assert_includes track_section, %q{Its pull request's description is as "The pull request's description" says}
  end

  def test_it_tracks_the_implementation_of_a_spec_or_plan
    ["`Cadre:` line", "gh pr view <pr-url> --json body -q .body", "gh pr edit <pr-url> --body-file <file>",
     "milestone `<slug>/<i>`", "as \"Start a milestone\" says"].each { |text| assert_includes track_section, text }
  end

  def test_it_links_a_pull_request_by_hand_and_relays_the_cli_errors
    ["cadre pr link <pr-url> <slug>/<n> --json", "cadre pr link <pr-url> --none --json", "wins at its next sync", "`project_url`"].each { |text| assert_includes link_section, text }
    ["No milestone <slug>/<n> on <server>.", "GitHub has no pull request at <url>.", "GitHub isn't connected on <server> yet.",
     "tell the person, and stop", %q{as "Change a project" in [project.md](project.md) adds it},
     "url: is in a repo no project names"].each { |text| assert_includes milestone_refusals, text }
  end

  def test_it_links_a_pull_request_to_an_app
    assert_includes link_section, "cadre pr link <pr-url> <slug>/<n> --app <app> --json"
    assert_includes milestone_refusals, "app: must be lowercase letters, digits, - or _"
    refute_includes milestone, "app: needs a milestone"
  end

  def test_the_readme_and_brainstorm_name_apps
    assert_includes File.read(File.join(ROOT, "README.md")), "Cadre: <project>/<n> <app>"
    assert_includes read("brainstorm.md"), "apps of a repo that has several"
  end

  def test_the_readme_mentions_the_before_deploying_section
    assert_includes File.read(File.join(ROOT, "README.md")), "## Before deploying"
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
    assert_includes connect, "To connect or disconnect a Fly org, a Vercel team or a store's key, follow the section of that name under its platform."
    refute_match(/\bstep \d/, connect)
  end

  def test_it_shows_sets_and_unsets_a_repos_targets
    ["cadre repo show <repo> --json", "cadre repo set <repo> --fly-app <app> --json", "cadre repo set <repo> --platform <name> --json", "not tracked",
     "cadre repo unset <repo> --platform <name> --json", "any host other than Fly or Vercel"].each { |text| assert_includes connect, text }
    ["`platform`", "`settings`", "`account`", "`tracked`", "`name`: the app's name in the repo, unique across its platforms",
     "its `app` and `config` for Fly, its `project` and `dir` for Vercel", "`status_url`: next to `settings`, not inside it", "`last_deploy`",
     "`live`", '`"live"`', '`"not_live"`', '`"not_checked"`', "`not_live_since`"].each { |text| assert_includes target_fields, text }
    ["`stores`", "`public_build`", "That is expected"].each { |text| assert_includes target_fields, text }
    assert_includes connect, %q{"where does it release?" or "which build is public?" from `stores`}
    refute_includes connect, "`null` for Fly"
  end

  def test_it_asks_whether_an_app_is_a_further_one_or_a_move
    ["a further app or a move", "--name <existing>", "read `cadre repo show <repo> --json` again", "--fly-config <file>",
     "Report the target the JSON body holds"].each { |text| assert_includes fly_app, text }
    refute_includes everything, "To move an app instead"
  end

  def test_it_connects_a_fly_org_once_the_person_agrees_and_pipes_its_token
    ["Ask the person first", "fly tokens create readonly -o <org> -n cadre | cadre fly org add <org>", %q{as "Tokens and keys" says},
     "cadre fly org remove <org>", "in their own terminal", "No token given. Pipe it in, or type it when asked."].each { |text| assert_includes fly_org, text }
    assert_operator fly_org.index("Ask the person first"), :<, fly_org.index("| cadre fly org add <org>")
    ["<token>", "--token"].each { |text| refute_includes connect, text }
  end

  def test_it_connects_vercel_apps_and_teams
    ["--vercel-project", "--name <app>", "--vercel-dir", "`cadre deploy <repo>` deploys it, as [deploy.md](deploy.md) says",
     "`status_url_note`"].each { |text| assert_includes vercel_app, text }
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

  def refusal(text, prefix) = text[/^- `#{Regexp.escape(prefix)}.*$/] or flunk("no refusal #{prefix}")

  def test_it_reads_a_mobile_app_s_stores_field_by_field
    ["has a `label` (`App Store`, `Google Play`)", "the `app` it is there (the Apple ID or the package name)", "the `account` cadre reads it with",
     "`public_build`, the build that is public there", "its `version` (or `null` when the store gave none)", "its `build_number` and `since`",
     "`public_build` is `null` until cadre saw one", "A mobile app's own `account` is `null` and its `tracked` is `false`",
     "It is not a sign that the app isn't connected"].each { |text| assert_includes target_fields, text }
    assert_includes connect, %q{Answer "where does it deploy?" from these fields, and "where does it release?" or "which build is public?" from `stores`}
  end

  def test_it_asks_for_the_ids_a_mobile_app_needs
    ["the number in its App Store Connect address (`6443635924`)", "the Google Play package name (`com.example.app`)",
     "with `--name <app>` when the repo has more than one app"].each { |text| assert_includes mobile_app, text }
  end

  def test_it_says_once_when_cadre_shows_a_store_s_public_build
    ["Cadre asks each store which build is public and shows it on its Apps page", "each with the key or account that reads it",
     "within 15 minutes"].each { |text| assert_includes mobile_app, text }
    assert_equal 1, connect.scan("15 minutes").size
  end

  def test_a_store_key_file_is_asked_for_in_the_persons_terminal_and_never_read
    ["which asks for the key's `.p8` file", "which asks for the service account's JSON key file",
     "Once they say it is added, set the app that was waiting for it"].each { |text| assert_includes store_key, text }
    assert_includes tokens_and_keys, "Never ask the person to send you a token, a key or a key file, and never read one"
  end

  def test_it_explains_the_no_connected_key_error
    ["no connected key or account reads that app", "The parentheses say what cadre asked", "Check the Apple ID or the package name with the person",
     %q{as "Connect a store's key" says}].each { |text| assert_includes refusal(connect_refusals, "App Store: no connected key reads"), text }
  end

  def test_it_explains_the_https_only_refusal
    line = refusal(connect_refusals, "Cadre sends a key or a token over https only. Sign in to an https address first: cadre login --url https://<your cadre>.")
    ["isn't https, and nothing was sent", "Tell the person what it printed and stop", "they sign in again with an https address"].each { |text| assert_includes line, text }
  end

  def test_the_readme_says_how_a_mobile_app_is_connected
    bullet = File.read(File.join(ROOT, "README.md"))[/^- \*\*cadre\*\* — .*?(?=^- |\z)/m]
    ["Asked to connect a mobile app, it sets its App Store app and Google Play package with `cadre repo set`",
     "`cadre app-store key add` or `cadre google-play account add` in their own terminal", "Claude Code never handles a store's key"].each { |text| assert_includes bullet, text }
  end

  def test_a_new_app_store_key_means_setting_its_apps_again
    ["set again each app the old key read", "The old key stays connected until then.", "a new JSON key"].each { |text| assert_includes store_key, text }
    ["<key-id> still reads <repos>.", "then remove this one.", "Do that in that order with the person"].each { |text| assert_includes connect_refusals, text }
  end

  def test_a_token_or_key_never_passes_through_claude_code
    ["without passing through Claude Code", "in their own terminal", "for a Fly org only, the pipe",
     "Never ask the person to send you a token, a key or a key file",
     "never read one, print it, echo it, pass it as an argument, write it to a file or pipe it any other way"].each { |text| assert_includes tokens_and_keys, text }
    assert_equal 1, connect.scan(/never ask/i).size
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
  end

  def test_setting_an_app_again_is_said_once_and_carries_every_setting_over
    ["Setting an app again (the same name) replaces its settings", "Read what is there before setting it", "Carry them over",
     "`--fly-app`, `--fly-config` and `--status-url` each time, and `--name` when the app's name isn't its Fly app's",
     "A `--status-url` left out removes the URL",
     "A status URL left out is replaced by the production domain when it answers, and removed otherwise",
     "A Vercel target whose `status_url` is `null` keeps none only with `--no-status-url`, so ask the person whether it should stay unmonitored or take the default"].each do |text|
      assert_includes set_again, text
    end
    assert_equal 1, everything.scan(/replaces its settings/).size
    refute_match(/setting a platform again/i, everything)
  end

  def test_it_relays_the_deploy_target_errors
    ["Fly isn't connected on <server> yet. Add an org with cadre fly org add <org>.",
     "settings.app: isn't an app of a connected Fly org (", "Fly refused this token for <org>.",
     "Fly has no org <org> that this token can read.", "<org> still reads <repos>. Unset or move those targets first.",
     "No Fly org <org> on <server>.", "<repo> has no <Platform> target.", "No repo <repo> on <server>.",
     %q{as "Change a project" in [project.md](project.md) does}].each { |text| assert_includes connect_refusals, text }
  end

  def test_it_explains_the_vercel_error_lines
    ["Vercel isn't connected on <server> yet. Add a team with cadre vercel team add <team>.",
     "settings.project: isn't a project of a connected Vercel team (…)",
     "Vercel refused this token for <team>.", "Vercel has no team <team> that this token can read.",
     "<team> still reads <repos>. Unset or move those targets first.",
     "No Vercel team <team> on <server>.", "<repo> has no Vercel target <app>."].each { |text| assert_includes connect_refusals, text }
  end

  def test_it_relays_the_refusals_of_an_app_by_name
    ["<name> is already a <Platform> app of <repo>. Unset it first.",
     "<app> is already the <Platform> app of <other>, an app of <repo>. Set <other> instead, or unset it first.",
     "<repo> has <n> <Platform> apps: <apps>. Pass --name <app>.",
     "<repo> has no app <app>.", "there is nothing to remove; check the name with the person"].each { |text| assert_includes connect_refusals, text }
  end

  def test_it_relays_the_name_format_refusals
    ["`name: is required`", "`name: must be lowercase letters, digits, - or _`", "`name: isn't used on this platform`"].each { |text| assert_includes connect_refusals, text }
  end

  # deploy.md

  def deploy_steps = section(deploy, "# Deploy a repo")[/\A.*?(?=^## )/m]
  def deploy_anyway = section(deploy, "## Deploy anyway?")
  def tick_section = section(deploy, "## Tick a Before deploying item")
  def deploy_stops = section(deploy, "## When a deploy stops")

  def test_it_deploys_with_cadre_deploy_once_the_person_confirms
    ["cadre deploy <repo>", "Confirm first", "never run it without the confirmation", "Once the person confirms", "600000", "run_in_background",
     "last_deploy", "commit unknown", "lists them as `targets`, each with a `name` and a `platform`"].each { |text| assert_includes deploy_steps, text }
    assert_operator deploy_steps.index("Confirm first"), :<, deploy_steps.index("run the command in a checkout")
    ["fly deploy", "vercel deploy", "git status --porcelain"].each { |text| refute_includes deploy, text }
  end

  def test_cadre_deploy_is_the_one_way_to_deploy
    assert_includes deploy_steps, "`cadre deploy` is the one way to deploy here, whatever stops it. Never run a `fly` or `vercel` command to deploy."
  end

  def test_it_asks_which_app_to_deploy
    ["cadre repo show <repo> --json", "--app <name>", "--all", "only when the person asks for every app",
     "the deploy order puts first"].each { |text| assert_includes deploy_steps, text }
    ["<repo> has <n> apps: <apps>. Pass --app <name> or --all.", "<repo> has <n> apps: <apps>. Pass --app <name>, in deploy order.",
     "<repo> has no app <app>. Its apps: <apps>.",
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
    ["runs on Fly or Vercel", "vercel isn't installed", "vercel isn't signed in", "has no .vercelignore", "lacks what"].each { |text| assert_includes deploy, text }
  end

  def test_the_vercel_deploy_keeps_its_safety_rules
    ["You write no file named `.vercelignore`, anywhere", "You may propose its contents in chat only", "built but didn't go live",
     "relay the line saying which apps went live and which weren't promoted", "cadre stopped while promoting <app>",
     "tell the person to check Vercel for that app", "Running `cadre deploy <repo>` again builds and promotes them all, with the same `--app` or `--all`", "the person pushes it, or says to"].each { |text| assert_includes deploy_stops, text }
    ["Deploy anyway?", "exits 1 and builds nothing", "only once they confirm after seeing them all"].each { |text| assert_includes deploy_anyway, text }
  end

  def test_it_passes_yes_only_after_the_person_confirms_the_open_items
    ["Not deployed.", "cadre deploy <repo> --yes", "only once they confirm", %q{tick it as "Tick a Before deploying item" says}].each do |text|
      assert_includes deploy_anyway, text
    end
    assert_operator deploy_anyway.index("Not deployed."), :<, deploy_anyway.index("--yes")
    assert_includes deploy_stops, "fly auth login"
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

  def test_all_on_fly_deploys_in_the_release_queues_order
    assert_includes deploy, "`--all` on Fly apps deploys them one at a time, in the order Cadre's release queue lists them,"
    refute_includes deploy, "one at a time, by name"
  end

  def test_it_checks_the_fly_config_name_before_setting_it
    ["isn't in this checkout", "Neither fly.production.toml nor fly.toml is in this checkout.", "--fly-config <file>",
     "Check the file's name with the person before setting it",
     "the person confirms again before `cadre deploy <repo>` runs again, with the same `--app` or `--all`"].each { |text| assert_includes deploy_stops, text }
  end

  def test_setting_an_app_from_a_deploy_carries_its_settings_over
    pointer = %q{That sets the app again, so read "Set an app again" in [connect.md](connect.md) first and carry its}
    assert_equal 3, deploy_stops.scan(pointer).size
    ["carry its config file and status URL over", "carry its name and status URL over",
     "carry its status URL over, or pass `--no-status-url` when it has none and should stay unmonitored"].each { |text| assert_includes deploy_stops, text }
    command = deploy_stops.lines.find { |line| line.include?("--vercel-project <id> --name <app> --vercel-dir <folder>") }
    assert_includes command, "status URL"
  end

  def test_it_relays_a_deploy_of_an_app_with_no_fly_app
    ["<name> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app> --name <name>.",
     "<repo> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app>.",
     "<repo> has no app cadre can deploy.", "Then deploy again once they confirm"].each { |text| assert_includes deploy_stops, text }
  end

  def test_it_ticks_a_before_deploying_item_only_once_told_it_is_done
    ["gh pr view <pr-url> --json body -q .body", "`- [ ]` to `- [x]`", "gh pr edit <pr-url> --body-file <file>",
     "reads Held", "Tick only what the person said is done", "Items are ticked in GitHub",
     "In that repo's checkout, `gh pr view <number>` works with the number alone; from anywhere, pass its URL or `--repo <owner>/<repo>`.",
     "When the person's words match more than one item, ask which."].each { |text| assert_includes tick_section, text }
  end

  # Every skill file.

  def test_no_skill_file_names_colette
    skill_files.each { |path| refute_match(/colette/i, File.read(path), path) }
  end

  def test_skill_files_call_only_superpowers_skills_and_cadre_itself
    calls = skill_files.flat_map { |path| File.read(path).scan(/`([a-z][a-z0-9-]*:[a-z][a-z0-9-]*)`/).flatten }
    assert_equal %w[cadre:cadre superpowers:brainstorming superpowers:writing-plans], calls.uniq.sort
    skill_files.each { |path| refute_match(/\bEP-[A-Z]\d/, File.read(path), path) }
  end

  def test_no_skill_file_pushes_or_commits_everything
    # the person runs the tag push, never the agent (EP-I3)
    skill_files.each { |path| refute_match(/git (push(?! origin <tag>`)|commit -a|add (\.|-A))/, File.read(path), path) }
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

class BrainstormTest < Minitest::Test
  def brainstorm = File.read(File.join(PLUGIN, "skills", "cadre", "brainstorm.md"))

  def before_you_start = brainstorm[/^## Before you start\n(.*?)(?=^## )/m, 1]

  def test_it_stops_when_superpowers_brainstorming_is_missing
    ["`superpowers:brainstorming`", "`superpowers` plugin", "`claude-plugins-official`", "and stop"].each { |text| assert_includes before_you_start, text }
  end

  def test_it_runs_superpowers_brainstorming_as_written_with_cadres_rules_on_top
    ["Invoke `superpowers:brainstorming`", "follow it as written", "not through a workflow that wraps it", "Where they differ from it, they win"].each do |text|
      assert_includes brainstorm, text
    end
  end

  def test_it_leaves_the_conversation_to_superpowers
    ["wishing this existed", "one open question", "several approaches", "200–300 words"].each { |text| refute_includes brainstorm, text }
  end

  def test_its_rules_cover_what_superpowers_does_not
    ["even when it fits in one milestone", "the repos it touches", "must deploy first", "apps that use what changes",
     "without asking", "Ask before reading anything outside it", "Play the milestones back"].each { |text| assert_includes brainstorm, text }
  end

  def test_a_milestone_is_the_smallest_step_that_ships_one_feature_and_deploys_alone
    ["one feature", "smallest step", "previous version still runs", "out of users' reach", "a rollback loses no data",
     "installed mobile app versions", "deploy order", "never on a later one", "aim for 10", "20 code files",
     "two smaller", "never invent a split"].each { |text| assert_includes brainstorm, text }
  end

  def test_skipping_the_questions_leaves_one_approval_before_the_commit
    skip_path = brainstorm[/When the person says to skip the questions(.*?)$/, 1]
    ["still ends with the spec", "mark every open point as your call", "approve the spec"].each { |text| assert_includes skip_path, text }
  end

  def test_the_feature_spec_has_cadres_tracking_line_under_its_title
    ["the line under it that says it is tracked in Cadre", "step 3 of \"Create a project\" in [project.md](project.md)", "kebab case"].each { |text| assert_includes brainstorm, text }
  end

  def test_it_commits_only_the_spec_file
    assert_includes brainstorm, 'git commit -m "docs: <feature> design" -- <path>'
  end

  def test_it_hands_back_to_the_cadre_skill_instead_of_writing_plans
    ["instead of invoking `superpowers:writing-plans`", "Go back to step 2"].each { |text| assert_includes brainstorm, text }
  end

  def test_the_split_challenge_keeps_each_part_usable
    assert_includes brainstorm, "two smaller ones that each deploy and give someone something to use"
  end

  def test_it_writes_and_commits_the_feature_spec
    ["docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md", "`-2`", "## End goal", "## Increments", "### Increment <i> — ",
     "**Delivers:**", "**Deployable alone:**", "**Consumers:**", "**Code files:**",
     "plans increment 1", "until the person approves", "commit only the spec file", "never push"].each { |text| assert_includes brainstorm, text }
    refute_includes brainstorm, "Not shipped"
  end
end
