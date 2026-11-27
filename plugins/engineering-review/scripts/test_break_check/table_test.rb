require_relative "test_helper"
require_relative "../break_check"
require_relative "fake_profile"
require "stringio"

# --table BASE: only the proofs that belong to the change since BASE.
class TableTest < Minitest::Test
  include RepoHelper

  SETTINGS = {".break-check.json" => RepoHelper.settings({"fake" => FakeProfile.fields}), "test/a_test.exs" => "test"}.freeze

  def test_a_proof_on_an_added_line_is_a_row_and_one_in_an_untouched_file_is_not
    with_git_repo(SETTINGS.merge("lib/a.ex" => "a\nb\n", "lib/b.ex" => "x\ny\nz > 1\n")) do |root|
      File.write("lib/a.ex", "a\nb\nc > 1\n")
      prove(root, "added", "lib/a.ex", "c > 1")
      prove(root, "elsewhere", "lib/b.ex", "z > 1")

      code, out = table("HEAD")

      assert_equal 0, code
      assert_includes out, "<summary>Break checks (1)</summary>"
      assert_includes out, "| lib/a.ex:3 |"
      refute_includes out, "lib/b.ex"
      assert_includes table.last, "| lib/b.ex:3 |"
    end
  end

  def test_the_proofs_just_above_and_below_a_deletion_are_rows
    with_git_repo(SETTINGS.merge("lib/a.ex" => "a = 1\nb = 1\nc = 1\nd = 1\ne = 1\n")) do |root|
      File.write("lib/a.ex", "a = 1\nb = 1\nd = 1\ne = 1\n")
      {"two above" => "a = 1", "above" => "b = 1", "below" => "d = 1", "two below" => "e = 1"}.each do |name, from|
        prove(root, name, "lib/a.ex", from)
      end

      _, out = table("HEAD")

      assert_includes out, "<summary>Break checks (2)</summary>"
      assert_includes out, "`b = 1`"
      assert_includes out, "`d = 1`"
    end
  end

  def test_a_proof_in_an_untracked_file_is_a_row
    with_git_repo(SETTINGS.merge("lib/a.ex" => "a\n")) do |root|
      File.write("lib/new.ex", "n > 1\n")
      prove(root, "new", "lib/new.ex", "n > 1")

      assert_includes table("HEAD").last, "| lib/new.ex:1 |"
    end
  end

  def test_a_proof_outside_every_watched_path_is_a_row
    with_git_repo(SETTINGS.merge("lib/a.ex" => "a\n", "script/x.rb" => "x\n")) do |root|
      File.write("script/x.rb", "x\ny if z\n")
      prove(root, "script", "script/x.rb", "y if z")

      assert_includes table("HEAD").last, "| script/x.rb:2 |"
    end
  end

  def test_a_proof_in_a_file_the_change_only_renames_is_not_a_row
    with_git_repo(SETTINGS.merge("lib/old.ex" => "keep = 1\nkeep = 2\nkeep = 3\n")) do |root|
      git("mv", "lib/old.ex", "lib/moved.ex")
      commit("move")
      prove(root, "moved", "lib/moved.ex", "keep = 2")

      assert_includes table("HEAD~1").last, "<summary>Break checks (0)</summary>"
    end
  end

  def test_an_unknown_base_refuses
    with_git_repo(SETTINGS.merge("lib/a.ex" => "a\n")) do
      code, out = table("no-such-ref")

      assert_equal 2, code
      assert_includes out, "no-such-ref"
    end
  end

  private

  def prove(root, name, file, from)
    BreakCheck::Ledger.new(root).record(brk(name:, file:, from:, to: "#{from}!"), line: BreakCheck::Breaks.occurrences(File.read(file), from).first, tests_failed: ["t"], profile: "fake")
  end

  # `--table BASE`, or `--table` alone; returns [exit code, everything printed].
  def table(base = nil)
    out = StringIO.new
    [BreakCheck::CLI.run(["--table", *base], out:), out.string]
  end
end
