require "minitest/autorun"
require "json"

ROOT = File.expand_path("../../..", __dir__)
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
    assert_equal "0.9.0", manifest["version"]
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
end

class SkillTest < Minitest::Test
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
    ["to start a milestone (\"start milestone <project>/<n>\")", "to link a pull request to a milestone"].each { |text| assert_includes description, text }
  end

  def install_section = skill[/^## Install or update the CLI\n(.*?)(?=^## )/m, 1]
  
  def test_it_installs_a_missing_cli_and_upgrades_an_old_one
    assert_includes install_section, INSTALL
    ["When the command is missing,", "below `0.7.0`", "run `cadre upgrade`"].each { |text| assert_includes install_section, text }
    ["0.1.0", "below `0.2.0`", "below `0.3.0`", "below `0.4.0`", "below `0.5.0`", "below `0.6.0`"].each { |text| refute_includes skill, text }
  end

  def test_it_writes_a_spec_and_designs_for_every_milestone
    json = skill[/```json\n(.*?)```/m, 1]
    ["\"canvas_url\"", "\"design_url\"", "\"spec\""].each { |key| assert_includes json, key }
    ["one Claude Design canvas", "one page per milestone", "diagram", "share the canvas"].each { |text| assert_includes skill, text }
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

  def test_it_links_a_pull_request_by_hand_and_relays_the_cli_errors
    ["cadre pr link <pr-url> <slug>/<n> --json", "cadre pr link <pr-url> --none --json", "wins at its next sync",
     "No milestone <slug>/<n> on <server>.", "GitHub has no pull request at <url>.", "GitHub isn't connected on <server> yet.",
     "Cadre couldn't reach GitHub.", "url: is in a repo no project names"].each { |text| assert_includes link_section, text }
  end

  def skill_files = Dir[File.join(PLUGIN, "skills", "**", "*")].select { |path| File.file?(path) }
  def create_section = skill[/^## Create a project\n(.*?)(?=^## )/m, 1]

  def test_no_skill_file_names_colette
    skill_files.each { |path| refute_match(/colette/i, File.read(path), path) }
  end

  def test_skill_files_call_only_superpowers_skills
    calls = skill_files.flat_map { |path| File.read(path).scan(/`([a-z][a-z0-9-]*:[a-z][a-z0-9-]*)`/).flatten }
    assert_equal %w[superpowers:brainstorming superpowers:writing-plans], calls.uniq.sort
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
