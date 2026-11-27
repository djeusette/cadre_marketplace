require_relative "test_helper"
require_relative "../break_check"
require "open3"

class UncoveredTest < Minitest::Test
  include RepoHelper

  BASE_SOURCE = "defmodule A do\n  def x(a), do: a\nend\n"
  CHANGED_SOURCE = "defmodule A do\n  # Big or small.\n  def x(a) when a > 1, do: :big\n\n  def x(_a), do: :small\nend\n"

  def test_a_changed_line_with_no_proof_is_uncovered
    with_git_repo do |root|
      File.write("lib/a.ex", CHANGED_SOURCE)

      assert_equal [{file: "lib/a.ex", line: 3, text: "  def x(a) when a > 1, do: :big"},
        {file: "lib/a.ex", line: 5, text: "  def x(_a), do: :small"}],
        uncovered(root).call("HEAD")
    end
  end

  def test_a_line_inside_a_fresh_proof_is_covered
    with_git_repo do |root|
      File.write("lib/a.ex", CHANGED_SOURCE)
      BreakCheck::Ledger.new(root).record(brk(from: "a > 1"), line: 3, tests_failed: ["t"])

      assert_equal [5], uncovered(root).call("HEAD").map { _1[:line] }
    end
  end

  def test_a_multi_line_proof_covers_every_line_it_spans
    with_git_repo do |root|
      File.write("lib/a.ex", CHANGED_SOURCE)
      BreakCheck::Ledger.new(root).record(brk(from: "when a > 1, do: :big\n\n  def x(_a)", to: "x"), line: 3, tests_failed: ["t"])

      assert_equal [], uncovered(root).call("HEAD")
    end
  end

  def test_a_stale_proof_covers_nothing
    with_git_repo do |root|
      File.write("lib/a.ex", CHANGED_SOURCE)
      BreakCheck::Ledger.new(root).record(brk(from: "a > 1"), line: 3, tests_failed: ["t"])
      File.write("test/a_test.exs", "test, edited")

      assert_equal [3, 5], uncovered(root).call("HEAD").map { _1[:line] }
    end
  end

  def test_lines_inside_a_doc_block_are_left_out
    with_git_repo do |root|
      File.write("lib/a.ex", "defmodule A do\n  @moduledoc \"\"\"\n  Picks big or small.\n  \"\"\"\n\n  @doc \"\"\"\n  When a > 1.\n  \"\"\"\n  def x(a), do: a\n  def y, do: 1\nend\n")

      assert_equal [10], uncovered(root).call("HEAD").map { _1[:line] }
    end
  end

  def test_every_line_of_an_untracked_file_is_uncovered
    with_git_repo do |root|
      File.write("lib/new.ex", "def y(b) when b, do: 1\n\ndef y(_), do: 2\n")

      assert_equal [["lib/new.ex", 1], ["lib/new.ex", 3]], uncovered(root).call("HEAD").map { [_1[:file], _1[:line]] }
    end
  end

  def test_new_renamed_and_deleted_tracked_files
    with_git_repo do |root|
      File.write("lib/b.ex", "keep = 1\nkeep = 2\nkeep = 3\nkeep = 4\n")
      git("add", ".")
      git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "b")
      git("config", "diff.renames", "false")
      git("mv", "lib/b.ex", "lib/c.ex")
      File.write("lib/c.ex", "keep = 1\nkeep = 2\nkeep = 3\nkeep = 4\nadded = 5\n")
      File.write("lib/d.ex", "d = 4\n")
      git("add", ".")
      File.delete("lib/a.ex")

      assert_equal [["lib/c.ex", 5, "added = 5"], ["lib/d.ex", 1, "d = 4"]],
        uncovered(root).call("HEAD").map { [_1[:file], _1[:line], _1[:text]] }
    end
  end

  def test_an_added_line_that_starts_with_two_pluses_is_read_as_code
    with_git_repo do |root|
      File.write("lib/a.ex", "++ x\n")

      assert_equal [[1, "++ x"]], uncovered(root).call("HEAD").map { [_1[:line], _1[:text]] }
    end
  end

  def test_a_no_prefix_diff_setting_does_not_change_the_paths
    with_git_repo do |root|
      git("config", "diff.noprefix", "true")
      File.write("lib/a.ex", CHANGED_SOURCE)

      assert_equal ["lib/a.ex"], uncovered(root).call("HEAD").map { _1[:file] }.uniq
    end
  end

  def test_noise_lines_are_left_out_and_interpolation_is_kept
    with_git_repo do |root|
      File.write("lib/a.ex", "x do\n  # a comment\n  )\n  ]\n  }\n  end\n  \#{interpolated}\n")

      assert_equal [[1, "x do"], [7, "  \#{interpolated}"]], uncovered(root).call("HEAD").map { [_1[:line], _1[:text]] }
    end
  end

  def test_files_outside_the_watched_paths_are_left_out
    with_git_repo do |root|
      File.write("test/a_test.exs", "test\nmore")

      assert_equal [], uncovered(root).call("HEAD")
    end
  end

  def test_cli_lists_uncovered_lines_and_exits_1
    with_git_repo do
      File.write("lib/a.ex", CHANGED_SOURCE)

      code, out = run_cli(["--uncovered", "HEAD"])

      assert_equal 1, code
      assert_includes out, "lib/a.ex:3 |   def x(a) when a > 1, do: :big\n"
      assert_includes out, "2 changed lines have no fresh proof"
    end
  end

  def test_cli_exits_0_when_every_changed_line_is_covered
    with_git_repo do
      code, out = run_cli(["--uncovered", "HEAD"])

      assert_equal 0, code
      assert_includes out, "0 changed lines have no fresh proof"
    end
  end

  def test_an_unknown_base_refuses
    with_git_repo do
      code, out = run_cli(["--uncovered", "no-such-ref"])

      assert_equal 2, code
      assert_includes out, "no-such-ref"
    end
  end

  def test_paths_with_accents_and_spaces_are_read
    with_git_repo do |root|
      File.write("lib/café.ex", "x = 1\n")
      File.write("lib/a b.ex", "y = 1\n")
      git("add", ".")
      git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "names")
      File.write("lib/café.ex", "x = 2\n")
      File.write("lib/a b.ex", "y = 2\n")
      File.write("lib/né.ex", "z = 1\n")

      assert_equal [["lib/a b.ex", "y = 2"], ["lib/café.ex", "x = 2"], ["lib/né.ex", "z = 1"]],
        uncovered(root).call("HEAD").map { [_1[:file], _1[:text]] }.sort
    end
  end

  def test_the_profile_decides_what_is_watched_and_what_is_noise
    with_git_repo do |root|
      write("script/break_check/x.rb", "def y\n  # a comment\n  1 if z\nend\n")
      write("script/test/x_test.rb", "def test_y; end\n")

      lines = BreakCheck::Uncovered.new(root, BreakCheck::Profiles.build("minitest", MINITEST, partition: nil)).call("HEAD")

      assert_equal [["script/break_check/x.rb", "def y"], ["script/break_check/x.rb", "  1 if z"]], lines.map { [_1[:file], _1[:text]] }
    end
  end

  private

  def uncovered(root) = BreakCheck::Uncovered.new(root, BreakCheck::Profiles.build("exunit", EXUNIT, partition: nil))

  def run_cli(argv)
    out = StringIO.new
    [BreakCheck::CLI.run(argv, out:), out.string]
  end

  def with_git_repo
    with_repo("lib/a.ex" => BASE_SOURCE, "test/a_test.exs" => "test", ".break-check.json" => RepoHelper.settings({"exunit" => EXUNIT})) do |root|
      git("init", "-q")
      git("add", ".")
      git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "base")
      yield root
    end
  end

  def git(*args)
    _, status = Open3.capture2e("git", *args)
    raise "git #{args.join(" ")} failed" unless status.success?
  end
end
