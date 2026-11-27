require_relative "test_helper"
require_relative "../break_check/profile"

class ProfileTest < Minitest::Test
  include RepoHelper

  def test_a_missing_settings_file_refuses
    with_repo do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_equal "no .break-check.json in #{root}: run from the repository root, or write one (see contract.md)", error.message
    end
  end

  def test_a_settings_file_that_is_not_json_refuses
    with_repo(".break-check.json" => "{\"profiles\": ") do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_match(/\A\.break-check\.json is not JSON: .*unexpected/, error.message)
    end
  end

  def test_settings_without_a_profile_refuse
    ["[]", "{}", '{"profiles": {}}', '{"profiles": []}'].each do |text|
      with_repo(".break-check.json" => text) do |root|
        error = assert_raises(BreakCheck::Usage, text) { load_profile(root) }
        assert_equal ".break-check.json: profiles must name at least one profile", error.message, text
      end
    end
  end

  def test_an_unknown_top_level_key_refuses
    with_repo(".break-check.json" => JSON.generate("profiles" => {"minitest" => MINITEST}, "defualt" => "minitest")) do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_equal ".break-check.json: unknown key defualt", error.message
    end
  end

  def test_a_misspelt_profiles_key_is_named
    with_repo(".break-check.json" => JSON.generate("profile" => {"minitest" => MINITEST})) do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_equal ".break-check.json: unknown key profile", error.message
    end
  end

  def test_every_profile_is_checked_not_only_the_chosen_one
    files = {"script/break_check.rb" => "", "script/break_check/x.rb" => ""}
    with_repo(files.merge(".break-check.json" => settings({"a" => MINITEST, "b" => {}}, default: "a"))) do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_match(/\A\.break-check\.json: profile b: missing command/, error.message)
    end
    with_repo(files.merge(".break-check.json" => settings({"a" => MINITEST, "b" => MINITEST.merge("watched" => ["libs"])}, default: "a"))) do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_equal ".break-check.json: profile b: watched path libs does not exist", error.message
    end
  end

  def test_the_partition_goes_to_the_chosen_profile_only
    files = {"lib/a.ex" => "", "script/break_check.rb" => "", "script/break_check/x.rb" => ""}
    with_repo(files.merge(".break-check.json" => settings({"app" => EXUNIT, "scripts" => MINITEST}, default: "app"))) do |root|
      assert_equal({"MIX_TEST_PARTITION" => "2"}, load_profile(root, partition: 2).command.call(["t.exs"]).first)
    end
  end

  def test_load_all_gives_every_profile_and_the_default
    files = {"script/break_check.rb" => "", "script/break_check/x.rb" => ""}
    two = settings({"fast" => MINITEST.merge("timeout" => 5), "slow" => MINITEST.merge("timeout" => 50)}, default: "slow")
    with_repo(files.merge(".break-check.json" => two)) do |root|
      profiles, default = BreakCheck::Profiles.load_all(root, partition: nil)

      assert_equal({"fast" => 5, "slow" => 50}, profiles.transform_values(&:timeout))
      assert_equal %w[fast slow], profiles.values.map(&:name)
      assert_equal "slow", default
    end
    with_repo(files.merge(".break-check.json" => settings({"only" => MINITEST}))) do |root|
      assert_equal "only", BreakCheck::Profiles.load_all(root, partition: nil).last
    end
  end

  def test_load_all_gives_the_partition_only_where_it_is_named
    files = {"lib/a.ex" => "", "script/break_check.rb" => "", "script/break_check/x.rb" => ""}
    with_repo(files.merge(".break-check.json" => settings({"app" => EXUNIT, "scripts" => MINITEST}, default: "scripts"))) do |root|
      profiles, = BreakCheck::Profiles.load_all(root, partition: 3)

      assert_equal({"MIX_TEST_PARTITION" => "3"}, profiles["app"].command.call(["t.exs"]).first)
      assert_equal({}, profiles["scripts"].command.call(["t.rb"]).first)
    end
    with_repo(files.merge(".break-check.json" => settings({"scripts" => MINITEST}))) do |root|
      error = assert_raises(BreakCheck::Usage) { BreakCheck::Profiles.load_all(root, partition: 3) }
      assert_equal ".break-check.json: no profile takes --partition", error.message
    end
  end

  def test_two_profiles_without_a_default_refuse
    with_repo(".break-check.json" => settings({"a" => MINITEST, "b" => MINITEST}), "script/break_check.rb" => "") do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root, name: "a") }
      assert_equal ".break-check.json: default is required when there is more than one profile", error.message
    end
  end

  def test_a_default_that_names_no_profile_refuses
    with_repo(".break-check.json" => settings({"a" => MINITEST}, default: "b")) do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root, name: "a") }
      assert_equal ".break-check.json: default names no profile: b", error.message
    end
  end

  def test_the_named_profile_then_the_default_then_the_only_one_is_used
    two = settings({"fast" => MINITEST.merge("timeout" => 5), "slow" => MINITEST.merge("timeout" => 50)}, default: "slow")
    with_repo(".break-check.json" => two, "script/break_check.rb" => "", "script/break_check/x.rb" => "") do |root|
      assert_equal 5, load_profile(root, name: "fast").timeout
      assert_equal 50, load_profile(root).timeout
    end
    with_repo(".break-check.json" => settings({"only" => MINITEST.merge("timeout" => 7)}), "script/break_check.rb" => "", "script/break_check/x.rb" => "") do |root|
      assert_equal 7, load_profile(root).timeout
    end
  end

  def test_an_unknown_profile_name_refuses
    with_repo(".break-check.json" => settings({"minitest" => MINITEST})) do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root, name: "nope") }
      assert_equal "unknown profile nope (.break-check.json has minitest)", error.message
    end
  end

  def test_a_missing_required_key_refuses
    %w[command failing_test compile_error timeout watched noise].each do |key|
      assert_equal "profile p: missing #{key}", refusal(MINITEST.except(key)), key
    end
  end

  def test_an_unknown_profile_key_refuses
    assert_equal "profile p: unknown key refusals", refusal(MINITEST.merge("refusals" => "x"))
  end

  def test_the_optional_keys_are_optional
    profile = build(EXUNIT)
    assert_equal(/too_many_connections/, profile.infrastructure)
    assert_nil build(MINITEST).refusal
  end

  def test_a_pattern_that_is_not_a_regexp_refuses
    %w[failing_test compile_error infrastructure refusal noise doc_open doc_close].each do |key|
      assert_match(/\Aprofile p: #{key} is not a valid pattern: .*\(/, refusal(EXUNIT.merge(key => "(")), key)
      assert_equal "profile p: #{key} is not a valid pattern: it must be a string", refusal(EXUNIT.merge(key => 1)), key
    end
  end

  def test_inline_flags_reach_the_pattern
    assert build(MINITEST.merge("failing_test" => "(?m)A(.)B")).failing_test.match?("A\nB")
  end

  def test_a_failing_test_pattern_with_no_group_refuses
    assert_equal "profile p: failing_test needs a group that captures the test's name",
      refusal(MINITEST.merge("failing_test" => '(?:Failure|Error) \S+'))
  end

  def test_doc_open_and_doc_close_come_together
    assert_equal "profile p: doc_open and doc_close come together", refusal(EXUNIT.except("doc_close"))
    assert_equal "profile p: doc_open and doc_close come together", refusal(EXUNIT.except("doc_open"))
  end

  def test_a_profile_that_is_not_an_object_refuses
    assert_equal "profile p: must be an object", refusal(["ruby"])
  end

  def test_a_command_holds_files_once_as_a_whole_argument_after_the_program
    message = "profile p: command must be a list of strings holding {files} once, as a whole argument after the program"
    [["{files}"], %w[ruby {files} {files}], %w[ruby --files={files}], ["ruby", 1, "{files}"], "ruby {files}", []].each do |command|
      assert_equal message, refusal(MINITEST.merge("command" => command)), command.inspect
    end
  end

  def test_env_maps_names_to_strings
    [["X"], {"X" => 1}].each do |env|
      assert_equal "profile p: env must map names to strings", refusal(MINITEST.merge("env" => env)), env.inspect
    end
  end

  def test_the_timeout_is_a_positive_number_of_seconds
    [0, -1, "120"].each do |timeout|
      assert_equal "profile p: timeout must be a positive number of seconds", refusal(MINITEST.merge("timeout" => timeout)), timeout.inspect
    end
    assert_equal 0.5, build(MINITEST.merge("timeout" => 0.5)).timeout
  end

  def test_watched_is_a_list_of_paths
    [[], "lib", ["lib", 1]].each do |watched|
      assert_equal "profile p: watched must be a list of paths", refusal(MINITEST.merge("watched" => watched)), watched.inspect
    end
  end

  def test_the_ex_unit_command_runs_one_partition_in_a_fixed_order
    assert_equal [{"MIX_TEST_PARTITION" => "3"}, "mise", "exec", "--", "mix", "test", "--seed", "0", "test/a_test.exs"],
      build(EXUNIT, partition: 3).command.call(["test/a_test.exs"])
  end

  def test_files_and_partition_expand_where_they_stand
    fields = MINITEST.merge("command" => ["run", "--part={partition}", "{files}", "--end"], "env" => {"P" => "p{partition}", "Q" => "q"})

    assert_equal [{"P" => "p2", "Q" => "q"}, "run", "--part=2", "a.rb", "b.rb", "--end"], build(fields, partition: 2).command.call(["a.rb", "b.rb"])
    assert_equal [{}, "run", "--part=4", "a.rb"], build(MINITEST.merge("command" => ["run", "--part={partition}", "{files}"]), partition: 4).command.call(["a.rb"])
  end

  def test_the_ex_unit_command_needs_a_partition
    command = build(EXUNIT).command
    error = assert_raises(BreakCheck::Usage) { command.call(["t.exs"]) }
    assert_equal "--partition N is required to run tests with p", error.message
  end

  def test_a_profile_that_takes_no_partition_refuses_one
    assert_equal "profile p takes no --partition", refusal(MINITEST, partition: 1)
    assert_equal [{}, "ruby", "-e", "ARGV.each { require File.expand_path(_1) }", "t.rb"], build(MINITEST).command.call(["t.rb"])
  end

  def test_settings_are_read_as_utf_8_whatever_the_locale
    with_repo(".break-check.json" => settings({"tests →" => MINITEST}), "script/break_check.rb" => "", "script/break_check/x.rb" => "") do |root|
      with_ascii_locale { assert_equal 120, load_profile(root, name: "tests →").timeout }
    end
  end

  def test_a_watched_path_that_does_not_exist_refuses
    with_repo(".break-check.json" => settings({"minitest" => MINITEST}), "script/break_check.rb" => "") do |root|
      error = assert_raises(BreakCheck::Usage) { load_profile(root) }
      assert_equal ".break-check.json: profile minitest: watched path script/break_check does not exist", error.message
    end
  end

  private

  def build(fields, partition: nil) = BreakCheck::Profiles.build("p", fields, partition:)

  # The message `build` refuses `fields` with, without its file prefix.
  def refusal(fields, partition: nil)
    error = assert_raises(BreakCheck::Usage) { build(fields, partition:) }
    error.message.delete_prefix(".break-check.json: ")
  end

  def settings(...) = RepoHelper.settings(...)

  def load_profile(root, name: nil, partition: nil) = BreakCheck::Profiles.load(root, name:, partition:)
end
