require_relative "test_helper"
require_relative "../break_check"
require_relative "fake_profile"
require "digest"
require "rbconfig"
require "stringio"

class CliTest < Minitest::Test
  include RepoHelper

  FILES = {"lib/a.ex" => "mode=pass\n", "lib/b.ex" => "mode=pass\n", "test/a_test.exs" => "test",
    ".break-check.json" => RepoHelper.settings({"exunit" => RepoHelper::EXUNIT, "fake" => FakeProfile.fields}, default: "exunit")}.freeze

  def test_exit_is_0_only_when_every_break_is_caught
    with_repo(FILES.merge("lib/a.ex" => "mode=pass\nx = 1\n")) do
      caught_code, = cli([write_breaks([mode_break("fail")], "caught.json")])
      missed_code, out = cli([write_breaks([mode_break("fail"), brk(name: "missed", from: "x = 1", to: "x = 2")])])

      assert_equal 0, caught_code
      assert_equal 1, missed_code
      assert_includes out, "NOT CAUGHT  missed"
      assert_includes out, "1 caught, 1 not caught, 0 doesn't compile, 0 inconclusive"
    end
  end

  def test_a_red_baseline_refuses_to_run_records_nothing_and_shows_the_output_tail
    with_repo(FILES.merge("lib/a.ex" => "mode=garbage\nx = 1\n")) do |root|
      code, out = cli([write_breaks([brk(from: "x = 1", to: "x = 2")])])

      assert_equal 2, code
      assert_includes out, "something exploded"
      assert_empty BreakCheck::Ledger.new(root).entries
    end
  end

  def test_a_red_baseline_with_named_failures_shows_only_the_names
    with_repo(FILES.merge("lib/a.ex" => "mode=fail\nx = 1\n")) do
      code, out = cli([write_breaks([brk(from: "x = 1", to: "x = 2")])])

      assert_equal 2, code
      assert_includes out, "test big (ATest)"
      refute_includes out, "3 tests, 1 failure"
    end
  end

  def test_each_set_of_tests_is_green_before_its_breaks_run
    with_repo(FILES.merge("test/b_test.exs" => "test")) do
      File.write("lib/b.ex", "mode=pass\nalone_fails\n")
      code, out = cli([write_breaks([mode_break("fail"), brk(name: "b", file: "lib/b.ex", from: "alone_fails", to: "alone_fails_x", tests: ["test/b_test.exs"])])])

      assert_equal 2, code
      assert_includes out, "test b_test (BTest)"
    end
  end

  def test_another_mix_test_run_refuses
    with_repo(FILES.merge("lib/a.ex" => "mode=refuse\nx = 1\n")) do
      code, out = cli([write_breaks([brk(from: "x = 1", to: "x = 2")])])

      assert_equal 2, code
      assert_includes out, "Another mix test run"
    end
  end

  def test_a_check_first_miss_runs_nothing
    with_repo(FILES) do
      code, out = cli([write_breaks([brk(from: "not there")])])

      assert_equal 2, code
      assert_includes out, "0 occurrences"
      refute File.exist?(".invoked")
    end
  end

  def test_a_failed_restore_exits_3
    with_repo(FILES) do
      code, out = cli([write_breaks([mode_break("lock_file")])])

      assert_equal 3, code
      assert_includes out, "RESTORE FAILED"
    ensure
      File.chmod(0o644, "lib/a.ex")
    end
  end

  def test_stale_lists_replayable_and_gone_entries_and_exits_1
    with_repo(FILES.merge("lib/b.ex" => "mode=pass\ny = 1\n")) do
      cli([write_breaks([mode_break("fail"), mode_break("fail", name: "y", file: "lib/b.ex", from: "mode=pass\ny = 1")])])
      File.write("lib/a.ex", "mode=pass\n# edited\n")
      File.write("lib/b.ex", "mode=pass\n")

      code, out = cli(["--stale"])

      assert_equal 1, code
      assert_includes out, "replayable lib/a.ex:1 mode fail"
      assert_includes out, "gone lib/b.ex:1 y"
    end
  end

  def test_stale_exits_0_when_nothing_is_stale
    with_repo(FILES) do
      cli([write_breaks([mode_break("fail")])])

      assert_equal [0, "0 stale\n"], cli(["--stale"])
    end
  end

  def test_stale_replay_reruns_replayable_lines
    with_repo(FILES) do |root|
      cli([write_breaks([mode_break("fail")])])
      File.write("lib/a.ex", "mode=pass\n# edited\n")

      code, out = cli(["--stale", "--replay"])

      assert_equal 0, code
      assert_includes out, "caught  mode fail"
      BreakCheck::Ledger.new(root).entries => [entry]
      assert_equal Digest::SHA256.file("lib/a.ex").hexdigest, entry["hashes"]["lib/a.ex"]
    end
  end

  def test_stale_replay_drops_gone_lines_and_exits_1
    with_repo(FILES) do |root|
      cli([write_breaks([mode_break("fail")])])
      File.write("lib/a.ex", "mode=other\n")

      code, out = cli(["--stale", "--replay"])

      assert_equal 1, code
      assert_includes out, "gone lib/a.ex:1 mode fail"
      assert_includes out, "1 gone proof dropped"
      assert_empty BreakCheck::Ledger.new(root).entries
    end
  end

  def test_stale_replay_that_cannot_run_drops_nothing
    with_repo(FILES.merge("lib/b.ex" => "mode=pass\ny = 1\n")) do |root|
      cli([write_breaks([mode_break("fail"), mode_break("fail", name: "y", file: "lib/b.ex", from: "mode=pass\ny = 1")])])
      File.write("lib/a.ex", "mode=pass\n# edited\n")
      File.write("lib/b.ex", "mode=pass\n")

      code, out = run_cli(["--stale", "--replay"])

      assert_equal 2, code
      assert_includes out, "gone lib/b.ex:1 y"
      assert_includes out, "--partition"
      assert_equal 2, BreakCheck::Ledger.new(root).entries.size
    end
  end

  def test_stale_replay_with_nothing_stale_needs_no_partition
    with_repo(FILES) do
      assert_equal [0, ""], run_cli(["--stale", "--replay"])
    end
  end

  def test_the_ex_unit_profile_needs_a_partition_to_run_tests
    with_repo(FILES) do
      code, out = run_cli([write_breaks([mode_break("fail")])])

      assert_equal 2, code
      assert_includes out, "--partition"
    end
  end

  def test_table_prints_the_ledger
    with_repo(FILES) do
      cli([write_breaks([mode_break("fail")])])

      code, out = cli(["--table"])

      assert_equal 0, code
      assert_includes out, "| lib/a.ex:1 | `mode=pass` → `mode=fail` | test big (ATest) |"
    end
  end

  def test_no_command_prints_the_usage_and_refuses
    with_repo(FILES) do
      code, out = run_cli([])

      assert_equal 2, code
      assert_includes out, "Usage:"
      refute_includes out, "unexpected"
    end
  end

  def test_a_bad_option_value_refuses_plainly
    with_repo(FILES) do
      code, out = run_cli(["breaks.json", "--partition", "abc"])

      assert_equal 2, code
      assert_includes out, "invalid argument"
      refute_includes out, "unexpected"
    end
  end

  def test_an_inconclusive_break_prints_its_reason
    with_repo(FILES) do
      _, out = cli([write_breaks([mode_break("garbage")])])

      assert_includes out, "inconclusive  mode garbage  (failed with no test named"
    end
  end

  def test_two_breaks_files_refuse
    with_repo(FILES) do
      code, out = cli([write_breaks([mode_break("fail")]), write_breaks([mode_break("fail")], "other.json")])

      assert_equal 2, code
      assert_includes out, "one breaks file at a time"
    end
  end

  def test_two_commands_refuse
    with_repo(FILES) do
      code, out = cli([write_breaks([mode_break("fail")]), "--table"])

      assert_equal 2, code
      assert_includes out, "one command at a time"
    end
  end

  def test_replay_without_stale_refuses
    with_repo(FILES) do
      code, out = cli(["--replay"])

      assert_equal 2, code
      assert_includes out, "--replay goes with --stale"
    end
  end

  def test_an_unknown_profile_refuses
    with_repo(FILES) do
      code, out = run_cli([write_breaks([mode_break("fail")]), "--profile", "nope"])

      assert_equal 2, code
      assert_includes out, "unknown profile nope"
    end
  end

  def test_an_unreadable_breaks_file_refuses
    with_repo(FILES) do
      File.write("breaks.json", "[{")

      code, out = cli(["breaks.json"])

      assert_equal 2, code
      assert_includes out, "cannot read breaks file breaks.json"
    end
  end

  def test_a_breaks_file_that_is_not_an_array_refuses
    with_repo(FILES) do
      File.write("breaks.json", JSON.generate(mode_break("fail").to_h))

      code, out = cli(["breaks.json"])

      assert_equal 2, code
      assert_includes out, "a breaks file is a JSON array of breaks"
    end
  end

  def test_a_breaks_entry_that_is_not_an_object_refuses
    with_repo(FILES) do
      File.write("breaks.json", "[1]")

      code, out = cli(["breaks.json"])

      assert_equal 2, code
      assert_includes out, "each break must be an object"
    end
  end

  def test_an_unexpected_error_refuses_rather_than_reading_as_a_miss
    with_repo(FILES) do
      write(".breaks/ledger.jsonl", "{not json\n")

      code, out = run_cli(["--table"])

      assert_equal 2, code
      assert_includes out, "unexpected error"
    end
  end

  def test_term_mid_run_keeps_what_was_printed_and_stops_the_test_run
    with_repo(FILES) do |root|
      write_breaks([mode_break("fail"), mode_break("hang", file: "lib/b.ex")])
      File.write(".break-check.json", RepoHelper.settings({"fake" => FakeProfile.fields(timeout: 60)}))
      pid = Process.spawn(RbConfig.ruby, "-e", "require #{File.expand_path("../break_check.rb", __dir__).dump}; " \
        "$stdout.sync = true; exit BreakCheck::CLI.run(['breaks.json', '--profile', 'fake'], out: $stdout)",
        out: "out.txt", err: File::NULL)
      wait_for { File.exist?(".hang-pid") }
      test_run = File.read(".hang-pid").to_i

      Process.kill("TERM", pid)
      Process.wait(pid)

      assert_includes File.read("out.txt"), "caught  mode fail"
      assert_equal "mode=pass\n", File.read("lib/b.ex")
      assert_empty Dir["#{root}/.breaks/journal/*"]
      refute File.exist?("#{root}/.breaks/child")
      assert_raises(Errno::ESRCH) { Process.kill(0, -test_run) }
    end
  end

  def test_table_and_stale_refuse_without_settings
    with_repo(FILES.except(".break-check.json")) do
      [["--table"], ["--stale"]].each do |argv|
        code, out = run_cli(argv)

        assert_equal 2, code, argv.inspect
        assert_includes out, "no .break-check.json in #{Dir.pwd}", argv.inspect
      end
    end
  end

  def test_with_one_profile_the_profile_may_be_left_out
    with_repo(FILES.merge(".break-check.json" => RepoHelper.settings({"fake" => FakeProfile.fields}))) do
      assert_equal 0, run_cli([write_breaks([mode_break("fail")])]).first
    end
  end

  def test_a_partition_reaches_the_profile
    with_repo(FILES) do
      code, out = cli([write_breaks([mode_break("fail")]), "--partition", "1"])

      assert_equal 2, code
      assert_includes out, "profile fake takes no --partition"
    end
  end

  private

  # The CLI with the fake test command; returns [exit code, everything printed].
  def cli(argv) = run_cli(argv + ["--profile", "fake"])

  def run_cli(argv)
    out = StringIO.new
    [BreakCheck::CLI.run(argv, out:), out.string]
  end

  def wait_for(seconds: 15)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    sleep 0.05 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    flunk "gave up waiting after #{seconds}s" unless yield
  end
end
