require_relative "test_helper"
require_relative "../break_check"
require_relative "fake_profile"
require "digest"
require "stringio"

class RunTest < Minitest::Test
  include RepoHelper

  FILES = {"lib/a.ex" => "mode=pass\n", "lib/b.ex" => "mode=pass\n", "test/a_test.exs" => "test"}.freeze

  def test_a_failing_named_test_is_caught_and_recorded
    with_repo(FILES) do |root|
      outcomes = run_breaks([mode_break("fail")])

      assert_equal [:caught], outcomes.map(&:result)
      assert_equal ["test big (ATest)"], outcomes.first.tests_failed
      BreakCheck::Ledger.new(root).entries => [entry]
      assert_equal 1, entry["line"]
    end
  end

  def test_a_caught_break_records_its_profile
    with_repo(FILES) do |root|
      run_breaks([mode_break("fail")])

      BreakCheck::Ledger.new(root).entries => [entry]
      assert_equal "fake", entry["profile"]
    end
  end

  def test_utf_8_test_names_are_read_whatever_the_locale
    with_repo(FILES) do
      with_ascii_locale do
        assert_equal [["test a → b (ATest)"]], run_breaks([mode_break("fail_utf8")]).map(&:tests_failed)
      end
    end
  end

  def test_a_break_with_a_fresh_proof_is_skipped
    with_repo(FILES) do
      run_breaks([mode_break("fail")])
      File.delete(".invoked")

      out = StringIO.new
      outcomes = run_breaks([mode_break("fail")], out:)

      assert_equal [:caught], outcomes.map(&:result)
      assert_includes out.string, "proven  mode fail  (fresh in the ledger)"
      refute File.exist?(".invoked")
    end
  end

  def test_a_new_swap_on_a_proven_from_runs
    with_repo(FILES) do
      run_breaks([mode_break("fail")])

      outcomes = run_breaks([brk(name: "garbage", from: "mode=pass", to: "mode=garbage")])

      assert_equal [:inconclusive], outcomes.map(&:result)
    end
  end

  def test_a_name_a_live_proof_in_the_same_file_holds_refuses
    with_repo(FILES.merge("lib/a.ex" => "mode=pass\nx = 1\n")) do
      run_breaks([mode_break("fail", name: "guard")])

      error = assert_raises(BreakCheck::Refused) { run_breaks([brk(name: "guard", from: "x = 1", to: "x = 2")]) }
      assert_includes error.message, "guard: a proof in lib/a.ex already has this name"
    end
  end

  def test_a_new_break_may_take_a_gone_proofs_name
    with_repo(FILES.merge("lib/a.ex" => "mode=pass\nx = 1\n")) do
      run_breaks([mode_break("fail", name: "guard")])
      File.write("lib/a.ex", "mode=kept\nx = 1\n")

      outcomes = run_breaks([brk(name: "guard", from: "x = 1", to: "x = 2")])

      assert_equal [:not_caught], outcomes.map(&:result)
    end
  end

  def test_a_baseline_that_times_out_is_red_even_when_it_exits_0
    with_repo(FILES.merge("lib/a.ex" => "mode=hang_exit_0\nx = 1\n")) do
      assert_raises(BreakCheck::Refused) { run_breaks([brk(from: "x = 1", to: "x = 2")], timeout: 1) }
    end
  end

  def test_a_break_whose_proof_went_stale_runs_again
    with_repo(FILES) do
      run_breaks([mode_break("fail")])
      File.write("test/a_test.exs", "test, edited")

      out = StringIO.new
      run_breaks([mode_break("fail")], out:)

      assert_includes out.string, "caught  mode fail  ← test big (ATest)"
    end
  end

  def test_passing_tests_are_not_caught_and_nothing_is_recorded
    with_repo(FILES.merge("lib/a.ex" => "mode=pass\nx = 1\n")) do |root|
      outcomes = run_breaks([brk(from: "x = 1", to: "x = 2")])

      assert_equal [:not_caught], outcomes.map(&:result)
      assert_empty BreakCheck::Ledger.new(root).entries
    end
  end

  def test_a_named_test_with_a_passing_exit_is_not_caught
    with_repo(FILES) { assert_equal [:not_caught], run_breaks([mode_break("names_but_pass")]).map(&:result) }
  end

  def test_a_compile_error_is_doesnt_compile
    with_repo(FILES) { assert_equal [:doesnt_compile], run_breaks([mode_break("compile")]).map(&:result) }
  end

  def test_unparsed_failing_output_is_inconclusive
    with_repo(FILES) { assert_equal [:inconclusive], run_breaks([mode_break("garbage")]).map(&:result) }
  end

  def test_an_infrastructure_failure_is_rerun_once
    with_repo(FILES) do
      assert_equal [:caught], run_breaks([mode_break("infra_once")]).map(&:result)
      assert_equal "2", File.read(".attempts")
    end
  end

  def test_infrastructure_wins_over_failing_names
    with_repo(FILES) do |root|
      outcomes = run_breaks([mode_break("infra_and_fail")])

      assert_equal [[:inconclusive, "infrastructure failed twice"]], outcomes.map { [_1.result, _1.reason] }
      assert_empty BreakCheck::Ledger.new(root).entries
    end
  end

  def test_another_test_run_during_a_break_is_inconclusive
    with_repo(FILES) do
      assert_equal [[:inconclusive, "another test run"]], run_breaks([mode_break("refuse")]).map { [_1.result, _1.reason] }
    end
  end

  def test_a_break_that_runs_past_the_timeout_is_inconclusive_and_restored
    with_repo(FILES) do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      outcomes = run_breaks([mode_break("hang")], timeout: 1)
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      assert_operator elapsed, :<, 10, "the hung test run was not killed"
      assert_equal [:inconclusive], outcomes.map(&:result)
      assert_includes outcomes.first.reason, "timed out"
      assert_equal "mode=pass\n", File.read("lib/a.ex")
    end
  end

  def test_a_running_test_run_is_tracked_for_a_killed_run_to_name
    with_repo(FILES) do
      assert_equal [["test child tracked (ATest)"]], run_breaks([mode_break("child")]).map(&:tests_failed)
    end
  end

  def test_a_signal_with_no_test_run_in_flight_stops_nothing
    assert_nil BreakCheck::Run.new(profile: FakeProfile.call).send(:kill_child)
  end

  def test_the_signal_handlers_in_place_before_a_run_are_back_after_it
    with_repo(FILES) do
      handler = proc {}
      previous = trap("INT", handler)

      run_breaks([mode_break("fail")])

      assert_same handler, trap("INT", previous)
    end
  end

  def test_a_leftover_journal_is_restored_and_announced_before_anything_runs
    with_repo(FILES) do |root|
      write("#{root}/.breaks/journal/1.json",
        JSON.generate(path: "lib/a.ex", content: "mode=pass\n", broken: Digest::SHA256.hexdigest("mode=garbage\n")))
      File.write("lib/a.ex", "mode=garbage\n")

      out = StringIO.new
      outcomes = run_breaks([mode_break("fail")], out:)

      assert out.string.start_with?("RESTORED lib/a.ex FROM A KILLED RUN\n")
      assert_equal [:caught], outcomes.map(&:result)
    end
  end

  def test_a_ledger_line_is_written_before_the_next_break_starts
    with_repo(FILES) do
      outcomes = run_breaks([mode_break("fail"), mode_break("count_ledger", file: "lib/b.ex")])

      assert_equal ["test ledger has 1 (ATest)"], outcomes.last.tests_failed
    end
  end

  private

  def run_breaks(breaks, out: StringIO.new, timeout: 10)
    BreakCheck::Run.new(profile: FakeProfile.call(timeout:), out:).call(breaks)
  end
end
