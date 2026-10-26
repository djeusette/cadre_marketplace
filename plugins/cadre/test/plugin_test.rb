require "minitest/autorun"
require "json"

ROOT = File.expand_path("../../..", __dir__)
PLUGIN = File.join(ROOT, "plugins", "cadre")
INSTALL = 'gh release download -R djeusette/cadre_cli --pattern "cadre_$(uname -s)_$(uname -m).tar.gz" -O - | tar -xz -C ~/.local/bin cadre'

class ManifestTest < Minitest::Test
  def manifest = JSON.parse(File.read(File.join(PLUGIN, ".claude-plugin", "plugin.json")))
  def marketplace = JSON.parse(File.read(File.join(ROOT, ".claude-plugin", "marketplace.json")))
  def entry = marketplace.fetch("plugins").find { |plugin| plugin["name"] == "cadre" }

  def test_plugin_depends_on_colette_from_the_colette_marketplace
    assert_equal "cadre", manifest["name"]
    assert_equal ["colette@colette-club"], manifest["dependencies"]
    assert_equal ["colette-club"], marketplace["allowCrossMarketplaceDependenciesOn"]
  end

  def test_marketplace_is_cadre_and_links_its_repo
    assert_equal "cadre", marketplace["name"]
    assert_equal "https://github.com/djeusette/cadre_marketplace", manifest["repository"]
  end

  def test_marketplace_lists_cadre_last_at_the_plugin_version
    assert_equal "cadre", marketplace.fetch("plugins").last["name"]
    assert_equal "./plugins/cadre", entry["source"]
    assert_equal "0.5.0", manifest["version"]
    assert_equal manifest["version"], entry["version"]
  end

  def test_descriptions_match
    refute_empty manifest["description"]
    assert_equal manifest["description"], entry["description"]
  end

  def test_readme_lists_cadre
    assert_match(/^- \*\*cadre\*\* — /, File.read(File.join(ROOT, "README.md")))
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

  def install_section = skill[/^## Install or update the CLI\n(.*?)(?=^## )/m, 1]
  
  def test_it_installs_a_missing_cli_and_upgrades_an_old_one
    assert_includes install_section, INSTALL
    ["When the command is missing,", "below `0.5.0`", "run `cadre upgrade`"].each { |text| assert_includes install_section, text }
    ["0.1.0", "below `0.2.0`", "below `0.3.0`", "below `0.4.0`"].each { |text| refute_includes skill, text }
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

  def test_updating_a_spec_names_no_colette_skill
    refute_includes update_section, "colette:"
  end

  def test_limits_name_the_spec_and_link_rules
    ["100 000", "not blank", "https://", "2 000"].each { |text| assert_includes skill, text }
  end

  def test_it_turns_the_spec_into_bare_repo_names
    ["bare", "not `colette-club/colette-api`", "gh repo view --json name -q .name", "A file path is never a repo", "ask when unsure"].each { |text| assert_includes skill, text }
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
