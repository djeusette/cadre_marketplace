require_relative "test_helper"
require_relative "../break_check/diff"

class DiffTest < Minitest::Test
  include RepoHelper

  def test_a_deletion_in_the_middle_sits_between_the_lines_around_it
    with_git_repo("lib/a.ex" => "a\nb\nc\n") do |root|
      File.write("lib/a.ex", "a\nc\n")

      assert_equal [BreakCheck::Hunk.new(file: "lib/a.ex", added: [], deleted: ["b"], above: 1, below: 2)], since(root).hunks
    end
  end

  def test_a_deletion_at_the_top_of_a_file_has_line_0_above_it
    with_git_repo("lib/a.ex" => "a\nb\n") do |root|
      File.write("lib/a.ex", "b\n")

      assert_equal [[["a"], 0, 1]], since(root).hunks.map { [_1.deleted, _1.above, _1.below] }
    end
  end

  def test_a_deletion_at_the_end_of_a_file_has_the_last_line_above_it
    with_git_repo("lib/a.ex" => "a\nb\nc\n") do |root|
      File.write("lib/a.ex", "a\n")

      assert_equal [[["b", "c"], 1, 2]], since(root).hunks.map { [_1.deleted, _1.above, _1.below] }
    end
  end

  def test_a_changed_line_is_added_and_deleted_between_its_neighbours
    with_git_repo("lib/a.ex" => "a\nb\nc\nd\n") do |root|
      File.write("lib/a.ex", "a\nB\nC\nd\n")

      assert_equal [BreakCheck::Hunk.new(file: "lib/a.ex", added: [{file: "lib/a.ex", line: 2, text: "B"}, {file: "lib/a.ex", line: 3, text: "C"}],
        deleted: ["b", "c"], above: 1, below: 4)], since(root).hunks
    end
  end

  def test_a_deleted_file_has_no_hunk
    with_git_repo("lib/a.ex" => "a\n", "lib/b.ex" => "b\n") do |root|
      File.delete("lib/a.ex")

      assert_empty since(root).hunks
    end
  end

  def test_touched_holds_each_added_line_and_the_lines_around_each_deletion
    with_git_repo("lib/a.ex" => "a\nb\nc\nd\ne\n") do |root|
      File.write("lib/a.ex", "a\nB\nc\ne\nf\n")
      File.write("lib/new.ex", "n\n")

      assert_equal Set[["lib/a.ex", 2], ["lib/a.ex", 1], ["lib/a.ex", 3], ["lib/a.ex", 4], ["lib/a.ex", 5], ["lib/new.ex", 1]],
        since(root).touched
    end
  end

  def test_paths_limit_the_diff
    with_git_repo("lib/a.ex" => "a\n", "test/a_test.exs" => "t\n") do |root|
      File.write("lib/a.ex", "b\n")
      File.write("test/a_test.exs", "u\n")
      File.write("test/new_test.exs", "n\n")

      assert_equal ["lib/a.ex"], BreakCheck::Diff.since(root, "HEAD", ["lib"]).added.map { _1[:file] }
      assert_equal ["lib/a.ex", "test/a_test.exs", "test/new_test.exs"], since(root).added.map { _1[:file] }.sort
    end
  end

  def test_a_base_that_looks_like_an_option_is_a_revision_git_refuses
    with_git_repo("lib/a.ex" => "a\n") do |root|
      error = assert_raises(BreakCheck::Error) { BreakCheck::Diff.since(root, "--output=written") }

      assert_includes error.message, "--output=written"
      refute File.exist?("written")
    end
  end

  def test_a_path_git_quotes_refuses_rather_than_reading_as_unchanged
    with_git_repo("lib/a\"b.ex" => "a\nif x\n") do |root|
      File.write("lib/a\"b.ex", "a\n")

      error = assert_raises(BreakCheck::Error) { since(root) }
      assert_includes error.message, "lib/a"
    end
  end

  def test_an_untracked_file_whose_name_git_quotes_is_read
    with_git_repo("lib/a.ex" => "a\n") do |root|
      File.write("lib/q\"z.ex", "if x\n")

      assert_equal [["lib/q\"z.ex", "if x"]], since(root).added.map { [_1[:file], _1[:text]] }
    end
  end

  def test_a_changed_line_that_is_not_utf_8_is_read
    with_git_repo("lib/a.ex" => "\xFFa\n".b) do |root|
      File.binwrite("lib/a.ex", "\xFFb\n".b)

      assert_equal ["�b"], since(root).added.map { _1[:text] }
    end
  end

  # macOS refuses such a name; Linux, where CI runs, takes it.
  def test_an_untracked_file_whose_name_is_not_utf_8_is_read
    with_git_repo("lib/a.ex" => "a\n") do |root|
      name = "lib/\xFF.ex".b
      begin
        File.binwrite(name, "if x\n")
      rescue Errno::EILSEQ
        skip "this filesystem refuses a name that is not UTF-8"
      end

      assert_equal [name], since(root).added.map { _1[:file].b }
    end
  end

  def test_untracked_paths_that_are_not_files_hold_no_lines
    with_git_repo("lib/a.ex" => "a\n") do |root|
      File.symlink("missing.ex", "lib/dangling.ex")
      Dir.mkdir("nested")
      Dir.chdir("nested") { git("init", "-q") }
      File.write("lib/new.ex", "n\n")

      assert_equal [["lib/new.ex", 1]], since(root).added.map { [_1[:file], _1[:line]] }
    end
  end

  private

  def since(root) = BreakCheck::Diff.since(root, "HEAD")
end
