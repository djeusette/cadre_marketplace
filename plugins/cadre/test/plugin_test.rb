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
    assert_equal "0.24.0", manifest["version"]
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

  def skill = File.read(File.join(PLUGIN, "skills", "cadre", "SKILL.md"))
  def frontmatter = skill[/\A---\n(.*?)\n---\n/m, 1]
  def description = frontmatter[/^description: (.*)$/, 1]

  def test_frontmatter_has_only_name_and_description
    assert_match(/^name: cadre$/, frontmatter)
    assert_equal %w[description name], frontmatter.lines.map { |line| line[/\A(\w+):/, 1] }.compact.sort
    assert_operator description.length, :<=, 1024
    assert_match(/Use when/, description)
  end

  def test_description_covers_starting_a_milestone_and_linking_a_pull_request
    ["to start a milestone (\"start milestone <project>/<n>\")", "to link a pull request to a milestone",
     "to connect a repo to where it deploys, or a Fly org"].each { |text| assert_includes description, text }
  end

  def test_description_covers_implementing_a_tracked_spec_or_plan
    assert_includes description, "to implement a spec or plan that says it is tracked in Cadre"
  end

  def install_section = skill[/^## Install or update the CLI\n(.*?)(?=^## )/m, 1]
  
  def test_it_installs_a_missing_cli_and_upgrades_an_old_one
    assert_includes install_section, INSTALL
    ["When the command is missing,", "below `0.19.0`", "run `cadre upgrade`"].each { |text| assert_includes install_section, text }
    ["0.1.0", "below `0.16.0`", "below `0.15.0`", "below `0.14.0`", "below `0.13.0`", "below `0.12.0`", "below `0.11.0`", "below `0.2.0`", "below `0.3.0`", "below `0.4.0`", "below `0.5.0`", "below `0.6.0`", "below `0.7.0`", "below `0.8.0`"].each { |text| refute_includes skill, text }
  end

  def test_it_writes_a_spec_and_designs_for_every_milestone
    json = skill[/```json\n(.*?)```/m, 1]
    ["\"canvas_url\"", "\"design_url\"", "\"spec\""].each { |key| assert_includes json, key }
    ["one Claude Design canvas", "one page per milestone", "diagram", "share the canvas"].each { |text| assert_includes skill, text }
  end

  def design_section = skill[/^## Link a milestone to its design\n(.*?)(?=^## )/m, 1]

  def test_it_links_each_milestone_to_its_own_page
    ["[design_link.rb](design_link.rb)", "--page <id>", "--board <file>", "project/canvas.json", "keeps the canvas link", "address bar"].each do |text|
      assert_includes design_section, text
    end
    [create_section, change_section].each { |section| assert_includes section, 'as "Link a milestone to its design" says' }
    json = skill[/```json\n(.*?)```/m, 1]
    assert_includes json, "https://claude.ai/artifact/…#page-…"
    ["?page=", "claude.ai/design/p/"].each { |text| refute_includes skill, text }
  end

  def test_it_pushes_a_missing_spec_when_asked
    ["update the spec of", "cadre spec push <project>/<n> <file> --json", "No milestone"].each { |text| assert_includes skill, text }
  end

  def update_section = skill[/^## Update a milestone's spec\n(.*?)(?=^## )/m, 1]

  def test_it_pulls_a_spec_edits_it_and_pushes_it_with_its_base
    ["cadre spec pull <project>/<n> -o <file> --json", "--base <version>", "has no spec yet.", "changed since you pulled it. Pull it again.", "previous version", "pull again first"].each do |text|
      assert_includes update_section, text
    end
  end

  def test_it_no_longer_asks_before_replacing_a_spec
    ["nothing shows it yet", "ask the person before pushing"].each { |text| refute_includes skill, text }
  end

def change_section = skill[/^## Change a project\n(.*?)(?=^## )/m, 1]

def test_it_changes_and_archives_a_project
  assert_includes skill, "## Change a project"
  ["cadre project pull <slug> -o <file> --json", "cadre project update <file> --json", "cadre project archive <slug>",
   "cadre project unarchive <slug>", "changed since you pulled it", "is archived. Run cadre project unarchive"].each { |text| assert_includes change_section, text }
end

def test_changing_a_project_names_no_colette_skill
  refute_match(/colette:/, change_section)
end

def test_a_new_milestone_gets_its_spec_once_cadre_has_numbered_it
  assert_includes change_section, "cadre spec push <slug>/<n> <spec-file> --json"
  assert_includes change_section, "Pull the project again"
  assert_includes change_section, "no `number`, no `spec` and no `design_url`"
  refute_match(/with its spec written as/, change_section)
  assert_operator change_section.index("cadre project update <file> --json"), :<, change_section.index("cadre spec push <slug>/<n>")
  refute_includes change_section, "spec push <slug>/<n> <spec-file> --base"
end

def test_a_new_milestone_gets_its_page_and_its_number_is_reported
  ["Draw its page in the project's design canvas", "`design_url`", "Report the new number"].each { |text| assert_includes change_section, text }
end

def test_an_unarchived_project_keeps_its_file_and_a_stale_key_signs_in_again
  assert_includes change_section, "continue with the same file: unarchiving doesn't change the version"
  assert_includes change_section, "Your key for <url> is no longer valid. Run cadre login --url <url>."
end

  def start_section = skill[/^## Start a milestone\n(.*?)(?=^## )/m, 1]
  def link_section = skill[/^### Link a pull request by hand\n(.*?)(?=^## )/m, 1]

  def test_starting_a_milestone_comes_between_changing_a_project_and_the_limits
    assert_operator skill.index("## Change a project"), :<, skill.index("## Start a milestone")
    assert_operator skill.index("## Start a milestone"), :<, skill.index("## Limits")
  end

  def test_it_starts_a_milestone_with_one_plan_and_one_pull_request_per_repo
    ["cadre project pull", "cadre spec pull <slug>/<n>", "docs/superpowers/specs/<slug>-<n>.md", "`superpowers:writing-plans`",
     "Cadre: <slug>/<n>", "in its own session", "one plan and one pull request", "gh repo view --json name -q .name"].each do |text|
      assert_includes start_section, text
    end
  end

  def test_it_commits_only_the_spec_copy
    ["git add <path>", 'git commit -m "docs: spec of <slug>/<n>" -- <path>', "cadre never reads"].each { |text| assert_includes start_section, text }
  end

  def test_it_commits_the_spec_copy_on_the_milestones_branch_never_on_the_default_branch
    ["gh repo view --json defaultBranchRef -q .defaultBranchRef.name", "git switch -c <slug>-<n>", "git switch <slug>-<n>",
     "never on the default branch"].each { |text| assert_includes start_section, text }
    assert_operator start_section.index("git switch -c <slug>-<n>"), :<, start_section.index("git add <path>")
  end

  def test_it_skips_the_commit_when_the_spec_copy_is_unchanged
    assert_includes start_section, "already holds this text, as when a milestone is started again, skip the commit"
  end

  def test_it_names_a_milestones_apps
    ["cadre repo show <repo> --json", '"repos": ["kinfield/kinfield", "kinfield/kinfield-family"]', "the API before the frontend",
     "A repo with one app stays a bare repo", "When the spec doesn't say which apps, ask the person",
     "An app that isn't connected yet can be named", "No repo <repo> on <server>.", "stays a bare `repo` unless the spec names its apps"].each do |text|
      assert_includes create_section, text
    end
    assert_includes change_section, 'name their apps, as "Create a project" says under "Apps in `repos`"'
    assert_includes skill[/^## Limits\n(.*)/m, 1], "| `repos` | 1–10 per milestone, no repeats, each `repo` or `repo/app`"
  end

  def test_it_starts_a_milestone_from_its_app_steps
    ["a repo/app entry is its repo", "one plan and one pull request per repo, or per app", "`Cadre: <slug>/<n> <app>` for a pull request for one app",
     "the first step with no pull request", "the branch is `<slug>-<n>-<app>` instead", "gh pr list --repo <owner>/<repo> --state all --search",
     "A closed, unmerged pull request holds nothing", "`gh repo view --json owner -q .owner.login`", "also matches `<slug>/20`", "names exactly `<slug>/<n>`, optionally followed by an app", "A line whose app isn't such a name links nothing"].each { |text| assert_includes start_section, text }
    assert_includes start_section.split("### Track").first, "the header's last line names it"
    assert_includes start_section.split("### Track").first, "Its pull request's description has the line `Cadre: <slug>/<n> <app>`.\n     ```"
    assert_includes track_section, "with the app after it when the pull request is for one app"
  end

  def test_it_links_a_pull_request_to_an_app
    ["cadre pr link <pr-url> <slug>/<n> --app <app> --json",
     "app: must be lowercase letters, digits, - or _"].each { |text| assert_includes link_section, text }
    refute_includes link_section, "app: needs a milestone"
  end

  def test_the_readme_and_brainstorm_name_apps
    assert_includes File.read(File.join(ROOT, "README.md")), "Cadre: <project>/<n> <app>"
    assert_includes File.read(File.join(PLUGIN, "skills", "cadre", "brainstorm.md")), "apps of a repo that has several"
  end

  def test_the_plan_says_it_is_tracked_in_cadre
    assert_includes start_section, PLAN_LINE
  end

  def track_section = skill[/^### Track a milestone's implementation\n(.*?)(?=^##)/m, 1]

  def test_it_tracks_the_implementation_of_a_spec_or_plan
    ["`Cadre: <slug>/<n>`", "gh pr view <pr-url> --json body -q .body", "gh pr edit <pr-url> --body-file <file>",
     "milestone `<slug>/<i>`", "as \"Start a milestone\" says"].each { |text| assert_includes track_section, text }
    assert_operator skill.index("### Track a milestone's implementation"), :<, skill.index("### Link a pull request by hand")
  end

  def test_the_pull_request_lists_what_a_deploy_needs_first
    start_rules = start_section.split("### Track").first
    ["a heading line `## Before deploying`", "- [ ]", "env var", "another repo", "manual step"].each do |text|
      assert_includes start_rules, text
      assert_includes track_section, text
    end
  end

  def test_the_readme_mentions_the_before_deploying_section
    assert_includes File.read(File.expand_path("../../../README.md", __dir__)), "## Before deploying"
  end

  def test_it_links_a_pull_request_by_hand_and_relays_the_cli_errors
    ["cadre pr link <pr-url> <slug>/<n> --json", "cadre pr link <pr-url> --none --json", "wins at its next sync",
     "No milestone <slug>/<n> on <server>.", "GitHub has no pull request at <url>.", "GitHub isn't connected on <server> yet.",
     "Cadre couldn't reach GitHub.", "url: is in a repo no project names"].each { |text| assert_includes link_section, text }
  end

  def deploy_section = skill[/^## Connect a repo to where it deploys\n(.*?)(?=^## )/m, 1]

  def test_connecting_a_repo_comes_between_starting_a_milestone_and_the_limits
    assert_operator skill.index("## Start a milestone"), :<, skill.index("## Connect a repo to where it deploys")
    assert_operator skill.index("## Connect a repo to where it deploys"), :<, skill.index("## Limits")
  end

  def test_it_shows_sets_and_unsets_a_repos_targets
    ["cadre repo show <repo> --json", "`platform`", "`settings`", "`account`", "`tracked`",
     "cadre repo set <repo> --fly-app <app> --json", "cadre repo set <repo> --platform <name> --json", "not tracked",
     "cadre repo unset <repo> --platform <name> --json"].each { |text| assert_includes deploy_section, text }
  end

  def test_it_connects_a_fly_org_once_the_person_agrees_and_pipes_its_token
    ["ask the person first", "fly tokens create readonly -o <org> -n cadre | cadre fly org add <org>", "never print it",
     "cadre fly org remove <org>", "in their own terminal"].each { |text| assert_includes deploy_section, text }
    assert_operator deploy_section.index("ask the person first"), :<, deploy_section.index("| cadre fly org add <org>")
    ["<token>", "--token"].each { |text| refute_includes deploy_section, text }
  end

  def test_it_relays_the_deploy_target_errors
    ["Fly isn't connected on <server> yet. Add an org with cadre fly org add <org>.",
     "settings.app: isn't an app of a connected Fly org (", "Fly refused this token for <org>.",
     "Fly has no org <org> that this token can read.", "<org> still reads <repos>. Unset or move those targets first.",
     "Cadre couldn't reach Fly. Try again in a minute.", "No repo <repo> on <server>."].each { |text| assert_includes deploy_section, text }
  end

  def deploy_a_repo_section = skill[/^## Deploy a repo\n(.*?)(?=^## )/m, 1]

  def test_deploying_a_repo_comes_between_connecting_and_the_limits
    assert_operator skill.index("## Connect a repo to where it deploys"), :<, skill.index("## Deploy a repo")
    assert_operator skill.index("## Deploy a repo"), :<, skill.index("## Limits")
  end

  def test_the_description_offers_to_deploy_a_repo_that_runs_on_fly
    assert_includes skill[/^description: (.*)$/, 1], "to deploy a repo that runs on Fly"
  end

  def test_it_deploys_with_cadre_deploy_once_the_person_confirms
    ["cadre deploy <repo>", "Once the person confirms", "600000", "run_in_background", "last_deploy",
     "commit unknown"].each { |text| assert_includes deploy_a_repo_section, text }
    ["fly deploy", "git status --porcelain"].each { |text| refute_includes deploy_a_repo_section, text }
  end

  def test_it_deploys_vercel_repos_too
    ["runs on Fly or Vercel", "vercel isn't installed", "vercel isn't signed in", "has no .vercelignore", "lacks what"].each { |t| assert_includes deploy_a_repo_section, t }
  end

  def test_the_vercel_deploy_keeps_its_safety_rules
    refute_includes deploy_a_repo_section, "vercel deploy"
    ["You write no file named `.vercelignore`, anywhere", "Deploy anyway?", "built but didn't go live",
     "exits 1 and builds nothing", "only once they confirm after seeing them all",
     "relay the line saying which apps went live and which weren't promoted", "cadre stopped while promoting <app>",
     "tell the person to check Vercel for that app", "Running `cadre deploy <repo>` again builds and promotes them all"].each { |t| assert_includes deploy_a_repo_section, t }
  end

  def tick_section = skill[/^### Tick a Before deploying item\n(.*?)(?=^## )/m, 1]

  def test_it_ticks_a_before_deploying_item_only_once_told_it_is_done
    ["gh pr view <pr-url> --json body -q .body", "`- [ ]` to `- [x]`", "gh pr edit <pr-url> --body-file <file>",
     "reads Held", "Tick only what the person said is done",
     "In that repo's checkout, `gh pr view <number>` works with the number alone; from anywhere, pass its URL or `--repo <owner>/<repo>`.",
     "When the person's words match more than one item, ask which."].each { |text| assert_includes tick_section, text }
    assert_operator skill.index("## Deploy a repo"), :<, skill.index("### Tick a Before deploying item")
    assert_operator skill.index("### Tick a Before deploying item"), :<, skill.index("## Limits")
  end

  def test_it_passes_yes_only_after_the_person_confirms_the_open_items
    ["Not deployed.", "cadre deploy <repo> --yes", "fly auth login", "only once they confirm"].each do |text|
      assert_includes deploy_a_repo_section, text
    end
    assert_operator deploy_a_repo_section.index("Not deployed."), :<, deploy_a_repo_section.index("--yes")
  end

  def test_it_checks_the_fly_config_name_before_setting_it_and_never_deploys_another_way
    ["isn't in this checkout", "Neither fly.production.toml nor fly.toml is in this checkout.", "--fly-config <file>",
     "check the file's name with the person", "never deploy another way",
     "the person confirms again before `cadre deploy <repo>` runs again"].each do |text|
      assert_includes deploy_a_repo_section, text
    end
  end

  def test_it_carries_the_status_url_over_when_it_sets_the_config_file
    ["with `--status-url <url>` when the target has one", "carry the status URL over"].each do |text|
      assert_includes deploy_a_repo_section, text
    end
  end

  def test_it_asks_whether_an_app_is_a_further_one_or_a_move
    ["a further app or a move", "--name <existing>", "read `cadre repo show <repo> --json` again"].each { |text| assert_includes deploy_section, text }
    refute_includes skill, "To move an app instead"
  end

  def test_it_removes_an_app_by_name
    assert_includes deploy_section, "cadre repo unset <repo> --name <app> --json"
    refute_includes deploy_section, "--platform vercel --name <app>"
  end

  def test_it_says_every_target_has_a_name
    refute_includes deploy_section, "`null` for Fly"
  end

  def test_it_relays_the_refusals_of_an_app_by_name
    ["<name> is already a <Platform> app of <repo>. Unset it first.",
     "<app> is already the <Platform> app of <other>, an app of <repo>. Set <other> instead, or unset it first.",
     "<repo> has <n> <Platform> apps: <apps>. Pass --name <app>.",
     "<repo> has no app <app>."].each { |text| assert_includes deploy_section, text }
  end

  def test_it_asks_which_app_to_deploy
    ["cadre repo show <repo> --json", "--app <name>", "--all", "only when the person asks for every app",
     "the deploy order puts first", "<repo> has <n> apps: <apps>. Pass --app <name> or --all.",
     "<repo> has no app <app>. Its apps: <apps>.",
     "<repo> has apps on more than one platform. Deploy each with --app <name>, in deploy order."].each { |text| assert_includes deploy_a_repo_section, text }
    refute_includes deploy_a_repo_section, "cadre deploy can't deploy it yet"
  end

  def test_it_relays_the_name_format_refusals
    ["`name: is required`", "`name: must be lowercase letters, digits, - or _`", "`name: isn't used on this platform`"].each { |text| assert_includes deploy_section, text }
  end

  def test_it_relays_a_deploy_of_an_app_with_no_fly_app
    ["<name> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app> --name <name>.",
     "<repo> has no Fly app. Connect it with cadre repo set <repo> --fly-app <app>.",
     "<repo> has no app cadre can deploy."].each { |text| assert_includes deploy_a_repo_section, text }
  end

  def test_the_config_hint_names_the_app_when_its_name_is_another
    assert_includes deploy_a_repo_section, "with `--name <app>` when the app's name isn't its Fly app's"
  end

  def test_connecting_a_repo_can_name_its_fly_config
    assert_includes deploy_section, "--fly-config <file>"
  end

  def test_it_asks_for_a_status_url_when_it_connects_a_repo
    ["--status-url", "https", "2xx", "isn't monitored", "every 2 minutes", "health checks", "Deployed", "mobile"].each { |text| assert_includes deploy_section, text }
  end

  def test_it_passes_every_flag_again_when_it_sets_an_app_again
    assert_includes deploy_section, "Setting an app again (the same name) replaces its settings, so pass `--fly-app`, `--fly-config` and `--status-url` each time, and `--name` when the app's name isn't its Fly app's"
    refute_match(/setting a platform again/i, skill)
  end

  def test_it_reads_the_target_before_it_sets_an_app_again
    assert_includes deploy_section, "Before setting an app again, read what is there"
    ["`settings` (its `app` and `config` for Fly, its `project` and `dir` for Vercel)", "`status_url`", "next to `settings`, not inside it", "carry them over"].each { |text| assert_includes deploy_section, text }
  end

  def test_it_needs_the_cli_that_sets_no_status_url
    assert_includes skill, "below `0.19.0`"
    refute_includes skill, "below `0.17.0`"
  end

  def step(number) = deploy_section[/^#{number}\. .*$/]

  def test_it_connects_a_mobile_app
    ["--app-store-app <id>", "--play-package <name>", "Apple ID", "pass both each time", "takes no status URL"].each { |text| assert_includes step(9), text }
    assert_includes skill[/^description: (.*)$/, 1], "to connect a mobile app to its stores"
    assert_includes step(9), "cadre refuses `--status-url`"
    assert_includes deploy_section, "- `App Store: no connected key reads <id> (asked: <key-id>)`"
    assert_includes step(9), "pass both each time for an app on both stores, and the one it has for an app on one. A store left out is taken off"
  end

  def test_a_new_app_store_key_means_setting_its_apps_again
    ["set again each app the old key read", "a new JSON key"].each { |text| assert_includes step(10), text }
    ["still reads", "then remove", "in that order"].each { |text| assert_includes step(11), text }
    assert_includes step(10), "The old key stays connected until then."
  end

  def test_a_store_key_is_never_handled_by_claude_code
    ["cadre app-store key add <key-id> --issuer <issuer-id>", "cadre google-play account add", "their own terminal", "Setup page"].each { |text| assert_includes step(10), text }
    ["cadre app-store key remove <key-id>", "cadre google-play account remove <email>"].each { |text| assert_includes step(11), text }
  end

  def test_it_says_a_mobile_app_releases_through_the_stores
    assert_match(/^   - `<repo>'s releases go through the stores\.`: /, deploy_a_repo_section)
    assert_includes deploy_a_repo_section, "Apps page"
    assert_match(/^2\. Fly needs a clean, up-to-date `main` of that repo\./, deploy_a_repo_section)
  end

  def test_it_describes_a_mobile_app_s_stores
    ["`stores`", "`public_build`", "That is expected"].each { |text| assert_includes step(1), text }
    assert_includes step(9), "Report the stores"
  end

  def test_a_mobile_app_takes_no_status_url_is_said_in_one_place
    paragraph = deploy_section[/^   Every app with a server takes a status URL.*$/]
    assert_includes paragraph, "A mobile app takes none: see step 9."
    refute_includes paragraph, "is refused for it, as step 9 says"
  end

  def error_line(prefix) = deploy_section[/^- `#{Regexp.escape(prefix)}.*$/]

  def test_it_reads_a_mobile_app_s_stores_field_by_field
    ["each has a `label` (`App Store`, `Google Play`)", "the `app` it is there (the Apple ID or the package name)", "the `account` cadre reads it with", "`public_build`, the build that is public there", "its `version` (or `null` when the store gave none)", "its `build_number` and `since`", "`public_build` is `null` until cadre saw one"].each { |text| assert_includes step(1), text }
    ["A mobile app's own `account` is `null` and its `tracked` is `false`", "It is not a sign that the app isn't connected", "\"where does it release?\" or \"which build is public?\" from `stores`", "from these fields"].each { |text| assert_includes step(1), text }
  end

  def test_it_asks_for_the_ids_a_mobile_app_needs
    ["the number in its App Store Connect address (`6443635924`)", "the Google Play package name (`com.example.app`)", "with `--name <app>` when the repo has more than one app", "Setting the app again replaces its stores:"].each { |text| assert_includes step(9), text }
  end

  def test_it_says_once_when_cadre_shows_a_store_s_public_build
    ["Cadre asks each store which build is public", "shows it on its Apps page", "each with the key or account that reads it", "within 15 minutes"].each { |text| assert_includes step(9), text }
    assert_equal 1, step(9).scan("15 minutes").size
  end

  def test_a_store_key_file_is_asked_for_in_the_persons_terminal_and_never_read
    ["which asks for the key's `.p8` file", "which asks for the service account's JSON key file", "Never ask them to send you a key file, and never read one", "Once they say it is added, set the app that was waiting for it"].each { |text| assert_includes step(10), text }
  end

  def test_it_explains_the_no_connected_key_error
    ["no connected key or account reads that app", "The parentheses say what cadre asked", "Check the Apple ID or the package name with the person", "as in step 10"].each { |text| assert_includes error_line("App Store: no connected key reads"), text }
  end

  def test_it_explains_the_https_only_refusal
    line = error_line("Cadre sends a key or a token over https only. Sign in to an https address first: cadre login --url https://<your cadre>.")
    ["isn't https, and nothing was sent", "Tell the person what it printed and stop", "they sign in again with an https address"].each { |text| assert_includes line, text }
  end

  def test_the_readme_says_how_a_mobile_app_is_connected
    bullet = File.read(File.join(ROOT, "README.md"))[/^- \*\*cadre\*\* — .*?(?=^- |\z)/m]
    ["Asked to connect a mobile app, it sets its App Store app and Google Play package with `cadre repo set`", "`cadre app-store key add` or `cadre google-play account add` in their own terminal", "Claude Code never handles a store's key"].each { |text| assert_includes bullet, text }
  end

  def test_it_says_nothing_is_deployed_for_a_mobile_app
    assert_includes deploy_a_repo_section[/^   - `<repo>'s releases go through the stores\.`.*$/], "the app is a mobile app, and nothing is deployed"
  end

  def test_it_confirms_a_blocked_deploy_before_passing_yes
    ["`#<n> is Blocked: <app> should run #<m> first.`", "`#<n> is Blocked: <app> should deploy first.`",
     "the release queue shows Blocked", "With `--app`, it lists only that app's items and Blocked PRs.",
     "say which PR is Blocked and what should go first, and propose deploying that first",
     "Run `cadre deploy <repo> --yes` only once they confirm after seeing them all, with the same `--app` or `--all`."].each do |text|
      assert_includes deploy_a_repo_section, text
    end
    step = deploy_a_repo_section.lines.find { |line| line.start_with?("5. ") }
    assert_operator step.index("is Blocked:"), :<, step.index("--yes")
  end

  def test_under_all_a_blocked_pr_the_run_clears_is_said_to_be_cleared
    assert_includes deploy_a_repo_section,
                    "Under `--all`, when what should go first is an app the same run deploys first, say so: the run already deploys it first."
  end

  def test_all_on_fly_deploys_in_the_release_queues_order
    assert_includes deploy_a_repo_section, "`--all` on Fly apps deploys them one at a time, in the order Cadre's release queue lists them,"
    refute_includes deploy_a_repo_section, "one at a time, by name"
  end

  def test_it_connects_vercel_apps_and_teams
    ["--vercel-project", "--name <app>", "--vercel-dir", "cadre vercel team add", "cadre vercel team remove",
     "`cadre deploy <repo>` deploys it",
     "`project` and `dir`", "`name`, the app's name in the repo,",
     "any host other than Fly or Vercel", "(its `app` and `config` for Fly, its `project` and `dir` for Vercel)",
     "Account Settings, then Tokens", "a token scoped to the team"].each { |text| assert_includes deploy_section, text }
    assert_includes skill[/^description: (.*)$/, 1], "or a Fly org or a Vercel team, in Cadre (\"connect <repo> to its Fly app\", \"connect <repo> to its Vercel project\""
  end

  def test_it_asks_for_a_vercel_apps_status_url
    vercel_step = deploy_section.lines.find { |line| line.start_with?("6. ") }
    ["--status-url", "production domain", "--no-status-url", "status_url_note", "without redirecting", "login page"].each { |text| assert_includes vercel_step, text }
    refute_includes skill, "Don't ask for a status URL"
    refute_includes skill, "takes none yet"
  end

  def test_it_says_what_setting_an_app_again_does_to_its_status_url
    vercel_step = deploy_section.lines.find { |line| line.start_with?("6. ") }
    assert_includes vercel_step, "a status URL left out is replaced by the production domain when it answers, and removed otherwise"
    fly_step = deploy_section.lines.find { |line| line.start_with?("2. ") }
    assert_includes fly_step, "a `--status-url` left out removes the URL"
    read_step = deploy_section.lines.find { |line| line.start_with?("1. ") }
    assert_includes read_step, "a Vercel target whose `status_url` is `null` keeps none only with `--no-status-url`, so ask the person whether it should stay unmonitored or take the default"
    assert_includes deploy_a_repo_section, "with `--no-status-url` when it has none and should stay unmonitored"
  end

  def test_it_carries_a_vercel_apps_status_url_over
    command = deploy_a_repo_section.lines.find { |line| line.include?("--vercel-project <id> --name <app> --vercel-dir <folder>") }
    assert_includes command, "--status-url"
  end

  def test_it_explains_all_eight_vercel_error_lines
    ["Vercel isn't connected on <server> yet. Add a team with cadre vercel team add <team>.",
     "settings.project: isn't a project of a connected Vercel team (…)",
     "Vercel refused this token for <team>.", "Vercel has no team <team> that this token can read.",
     "<team> still reads <repos>. Unset or move those targets first.",
     "No Vercel team <team> on <server>.", "<repo> has no Vercel target <app>.",
     "Cadre couldn't reach Vercel. Try again in a minute."].each { |text| assert_includes deploy_section, text }
  end

  def test_the_person_adds_the_vercel_token_themselves
    ["never handled by Claude Code", "`vercel tokens add` can only make a token for the whole account", "in their own terminal", "team-scoped", "dashboard"].each { |text| assert_includes deploy_section, text }
  end

  def test_connecting_a_repo_reads_the_last_deploy
    assert_includes deploy_section, "`last_deploy`"
  end

  def test_connecting_a_repo_reads_whether_the_app_is_live
    ["`live`", '`"live"`', '`"not_live"`', '`"not_checked"`', "`not_live_since`"].each do |text|
      assert_includes deploy_section, text
    end
  end

  def skill_files = Dir[File.join(PLUGIN, "skills", "**", "*")].select { |path| File.file?(path) }
  def create_section = skill[/^## Create a project\n(.*?)(?=^## )/m, 1]

  def test_no_skill_file_names_colette
    skill_files.each { |path| refute_match(/colette/i, File.read(path), path) }
  end

  def test_skill_files_call_only_superpowers_skills_and_cadre_itself
    calls = skill_files.flat_map { |path| File.read(path).scan(/`([a-z][a-z0-9-]*:[a-z][a-z0-9-]*)`/).flatten }
    assert_equal %w[cadre:cadre superpowers:brainstorming superpowers:writing-plans], calls.uniq.sort
    skill_files.each { |path| refute_match(/\bEP-[A-Z]\d/, File.read(path), path) }
  end

  def test_creating_a_project_brainstorms_through_brainstorm_md
    assert_includes create_section, "[brainstorm.md](brainstorm.md)"
    refute_match(/available skills|must be installed/, skill)
  end

  def test_it_builds_from_a_spec_the_person_names
    ["already has an `## End goal` and an `## Increments` section", "Never pick a spec on your own"].each { |text| assert_includes create_section, text }
  end

  def test_nothing_is_registered_before_the_person_approves
    assert_operator create_section.index("Register nothing until the person approves"), :<, create_section.index("cadre project create <file> --json")
  end

  def test_its_example_milestones_are_usable_slices_not_layers
    json = skill[/```json\n(.*?)```/m, 1]
    refute_includes json, "The API stores a reminder date"
    assert_includes json, "Members get a reminder before a wish expires"
  end

  def test_the_feature_spec_says_it_is_tracked_in_cadre
    [FEATURE_LINE, "Add the line when the spec lacks it", "change it on the spec's tracking line too"].each { |text| assert_includes create_section, text }
  end

  def write_section = skill[/^## Write a milestone's spec\n(.*?)(?=^## )/m, 1]

  def test_a_milestones_spec_says_it_is_tracked_in_cadre
    assert_includes write_section, MILESTONE_LINE
  end

  def test_a_corrected_spec_is_committed_alone_or_left_to_the_person
    ['git commit -m "docs: <feature> design" -- <path>', "leave the commit to them"].each { |text| assert_includes create_section, text }
  end

  def test_no_skill_file_pushes_or_commits_everything
    skill_files.each { |path| refute_match(/git (push|commit -a|add (\.|-A))/, File.read(path), path) }
  end

  def test_limits_name_the_spec_and_link_rules
    ["100 000", "not blank", "https://", "2 000"].each { |text| assert_includes skill, text }
  end

  def test_it_turns_the_spec_into_bare_repo_names
    ["bare", "not `acme/shop-api`", "gh repo view --json name -q .name", "A file path is never a repo", "ask when unsure"].each { |text| assert_includes skill, text }
  end

  def test_it_handles_a_key_that_stops_working
    ["exit code is 0 and the JSON holds an `email`", "go back to Sign in", "the repo that must deploy first listed first"].each { |text| assert_includes skill, text }
  end

def test_it_runs_the_login_in_the_background_and_relays_the_code
  ["run_in_background", "600000 ms", "Opening <uri> in your browser.", "Check that the page shows this code: <code>"].each { |text| assert_includes skill, text }
end

def test_it_reports_the_json_url_and_explains_zero_based_paths
  ["`url` field", "0-based positions", "milestones.1.repos.0"].each { |text| assert_includes skill, text }
  refute_includes skill, "Report the URL from"
end

  def test_it_asks_the_person_for_the_cadre_url
    ["ask the person for their Cadre URL", "Never guess it", "cadre login --url <url>"].each { |text| assert_includes skill, text }
    refute_match(/colette-cadre\.fly\.dev|CADRE_URL/, skill)
    refute_match(/run `cadre login`(?! --url)/, skill)
  end

  def test_it_never_asks_for_a_pasted_key
    refute_match(/paste/i, skill)
  end

  def test_it_uses_the_cli_copy
    ["Signed in as <email>.", "Not signed in. Run cadre login --url <url>.", "Your key for <url> is no longer valid. Run cadre login --url <url>.", "The code expired. Run cadre login --url <url> again.", "--url must be an http:// or https:// URL with a host"].each do |text|
      assert_includes skill, text
    end
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
    ["the line under it that says it is tracked in Cadre", "step 2 of the cadre skill's \"Create a project\"", "kebab case"].each { |text| assert_includes brainstorm, text }
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
