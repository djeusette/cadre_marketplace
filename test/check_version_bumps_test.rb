require "minitest/autorun"
require "fileutils"
require "json"
require "open3"
require "tmpdir"

SCRIPT = File.expand_path("../script/check_version_bumps.rb", __dir__)
GIT_ENV = {
  "GIT_CONFIG_GLOBAL" => File::NULL, "GIT_CONFIG_NOSYSTEM" => "1",
  "GIT_AUTHOR_NAME" => "Test", "GIT_AUTHOR_EMAIL" => "test@example.com",
  "GIT_COMMITTER_NAME" => "Test", "GIT_COMMITTER_EMAIL" => "test@example.com"
}.freeze

class CheckVersionBumpsTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    git "init", "-q", "-b", "main"
  end

  def teardown = FileUtils.remove_entry(@repo)

  def git(*args)
    out, status = Open3.capture2e(GIT_ENV, "git", *args, chdir: @repo)
    assert status.success?, out
  end

  def write(path, text)
    FileUtils.mkdir_p(File.dirname(File.join(@repo, path)))
    File.write(File.join(@repo, path), text)
  end

  def plugin(name, version)
    write("plugins/#{name}/.claude-plugin/plugin.json", JSON.generate({ "name" => name, "version" => version }.compact))
  end

  def commit
    git "add", "-A"
    git "commit", "-q", "-m", "change"
  end

  def tag_base
    commit
    git "tag", "base"
  end

  def check(*args)
    out, status = Open3.capture2e(GIT_ENV, "ruby", SCRIPT, *args, chdir: @repo)
    [out, status.exitstatus]
  end

  def test_a_change_without_a_bump_fails_and_names_the_plugin
    plugin("demo", "0.1.0")
    write("plugins/demo/skills/a.md", "one")
    tag_base
    write("plugins/demo/skills/a.md", "two")
    commit

    assert_equal ["plugins/demo changed but its version 0.1.0 is not above 0.1.0\n", 1], check("base")
  end

  def test_a_change_with_a_bump_passes
    plugin("demo", "0.1.0")
    tag_base
    plugin("demo", "0.1.1")
    commit

    assert_equal ["OK\n", 0], check("base")
  end

  def test_a_lowered_version_fails
    plugin("demo", "0.2.0")
    tag_base
    plugin("demo", "0.1.9")
    commit

    assert_equal ["plugins/demo changed but its version 0.1.9 is not above 0.2.0\n", 1], check("base")
  end

  def test_a_change_to_any_file_of_a_plugin_needs_a_bump
    plugin("demo", "0.1.0")
    tag_base
    write("plugins/demo/test/x_test.rb", "# a test")
    commit

    assert_equal ["plugins/demo changed but its version 0.1.0 is not above 0.1.0\n", 1], check("base")
  end

  def test_only_the_plugin_not_bumped_is_named
    plugin("bumped", "1.0.0")
    plugin("kept", "2.0.0")
    tag_base
    plugin("bumped", "1.1.0")
    write("plugins/kept/README.md", "new")
    commit

    assert_equal ["plugins/kept changed but its version 2.0.0 is not above 2.0.0\n", 1], check("base")
  end

  def test_a_file_moved_between_plugins_needs_both_bumped
    plugin("from", "1.0.0")
    plugin("to", "2.0.0")
    write("plugins/from/skills/moved.md", "a skill that moves\n" * 20)
    tag_base
    FileUtils.mkdir_p(File.join(@repo, "plugins/to/skills"))
    git "mv", "plugins/from/skills/moved.md", "plugins/to/skills/moved.md"
    commit

    assert_equal ["plugins/from changed but its version 1.0.0 is not above 1.0.0\n" \
                  "plugins/to changed but its version 2.0.0 is not above 2.0.0\n", 1], check("base")
  end

  def test_a_new_plugin_passes
    write("README.md", "a marketplace")
    tag_base
    plugin("fresh", "0.1.0")
    commit

    assert_equal ["OK\n", 0], check("base")
  end

  def test_a_new_plugin_without_a_version_fails
    write("README.md", "a marketplace")
    tag_base
    plugin("fresh", nil)
    commit

    assert_equal ["plugins/fresh has no version in .claude-plugin/plugin.json\n", 1], check("base")
  end

  def test_a_plugin_whose_base_has_no_version_passes_once_it_has_one
    plugin("demo", nil)
    tag_base
    plugin("demo", "0.1.0")
    commit

    assert_equal ["OK\n", 0], check("base")
  end

  def test_an_unreadable_version_fails_and_names_the_plugin
    plugin("demo", "0.35.0")
    tag_base
    plugin("demo", "v0.36.0")
    commit

    assert_equal ["plugins/demo has version \"v0.36.0\" in .claude-plugin/plugin.json, which is not a version number\n", 1], check("base")
  end

  def test_a_removed_plugin_passes
    plugin("gone", "1.0.0")
    write("README.md", "a marketplace")
    tag_base
    git "rm", "-rq", "plugins/gone"
    commit

    assert_equal ["OK\n", 0], check("base")
  end

  def test_a_change_outside_plugins_passes
    plugin("demo", "0.1.0")
    write("README.md", "one")
    tag_base
    write("README.md", "two")
    commit

    assert_equal ["OK\n", 0], check("base")
  end

  def test_an_unknown_base_fails
    plugin("demo", "0.1.0")
    commit

    out, status = check("origin/main")

    assert_equal 2, status
    assert_match(/origin\/main/, out)
    refute_includes out, "OK"
  end

  def test_no_base_prints_the_usage
    assert_equal ["Usage: ruby script/check_version_bumps.rb <base>\n", 2], check
  end
end
