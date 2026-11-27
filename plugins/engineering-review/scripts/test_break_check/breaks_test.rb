require_relative "test_helper"
require "json"

class BreaksTest < Minitest::Test
  include RepoHelper

  SOURCE = "defmodule A do\n  def x(a) when a > 1, do: :big\n  def x(_a), do: :small\nend\n"
  FILES = {"lib/a.ex" => SOURCE, "test/a_test.exs" => "test"}.freeze

  def test_load_reads_every_field
    with_repo do
      write("breaks.json", JSON.generate([{name: "n", file: "lib/a.ex", from: "a", to: "b", tests: ["test/a_test.exs"]}]))

      assert_equal [BreakCheck::Break.new(name: "n", file: "lib/a.ex", from: "a", to: "b", tests: ["test/a_test.exs"])],
        BreakCheck::Breaks.load("breaks.json")
    end
  end

  def test_load_names_the_entry_missing_a_key
    with_repo do
      write("breaks.json", JSON.generate([{name: "guard", file: "lib/a.ex", from: "a", tests: []}]))

      error = assert_raises(BreakCheck::Error) { BreakCheck::Breaks.load("breaks.json") }
      assert_includes error.message, "guard"
      assert_includes error.message, "to"
    end
  end

  def test_a_from_found_once_passes
    with_repo(FILES) { |root| assert_equal [], BreakCheck::Breaks.problems([brk], root:) }
  end

  def test_a_missing_from_reports_zero_occurrences
    with_repo(FILES) do |root|
      assert_equal ["a break: from not found in lib/a.ex (0 occurrences)"],
        BreakCheck::Breaks.problems([brk(from: "a < 1")], root:)
    end
  end

  def test_a_from_found_twice_reports_both_lines
    source = "x\n:ok\nx\nx\n:ok\n"
    with_repo(FILES.merge("lib/a.ex" => source)) do |root|
      problems = BreakCheck::Breaks.problems([brk(from: ":ok")], root:)
      assert_equal 1, problems.size
      problem = problems.first
      assert_includes problem, "2 occurrences"
      assert_includes problem, "lines 2, 5"
    end
  end

  def test_a_multi_line_from_matches_once
    with_repo(FILES.merge("lib/a.ex" => "if a do\n  b\nend\n")) do |root|
      assert_equal [], BreakCheck::Breaks.problems([brk(from: "if a do\n  b")], root:)
    end
  end

  def test_to_equal_to_from_is_a_problem
    with_repo(FILES) do |root|
      assert_equal ["a break: to is the same as from"], BreakCheck::Breaks.problems([brk(to: "a > 1")], root:)
    end
  end

  def test_a_missing_source_file_is_a_problem
    with_repo(FILES) do |root|
      assert_equal ["a break: lib/b.ex does not exist"], BreakCheck::Breaks.problems([brk(file: "lib/b.ex")], root:)
    end
  end

  def test_an_empty_tests_list_is_a_problem
    with_repo(FILES) do |root|
      assert_equal ["a break: names no test file"], BreakCheck::Breaks.problems([brk(tests: [])], root:)
    end
  end

  def test_a_missing_test_file_is_a_problem
    with_repo(FILES) do |root|
      assert_equal ["a break: test file test/b_test.exs does not exist"],
        BreakCheck::Breaks.problems([brk(tests: ["test/b_test.exs"])], root:)
    end
  end

  def test_two_breaks_with_one_name_in_one_file_are_a_problem
    with_repo(FILES.merge("lib/a.ex" => "a > 1\nb > 1\n")) do |root|
      problems = BreakCheck::Breaks.problems([brk(name: "guard"), brk(name: "guard", from: "b > 1", to: "b >= 1")], root:)

      assert_equal ["guard: another break in lib/a.ex has this name"], problems
    end
  end

  def test_load_refuses_tests_that_are_not_a_list_of_paths
    with_repo do
      write("breaks.json", JSON.generate([{name: "n", file: "lib/a.ex", from: "a", to: "b", tests: "test/a_test.exs"}]))

      error = assert_raises(BreakCheck::Error) { BreakCheck::Breaks.load("breaks.json") }
      assert_includes error.message, "tests must be a list of paths"
    end
  end

  def test_load_refuses_a_file_that_is_not_json
    with_repo do
      write("breaks.json", "[{")

      error = assert_raises(BreakCheck::Error) { BreakCheck::Breaks.load("breaks.json") }
      assert_includes error.message, "breaks.json"
    end
  end

  def test_load_refuses_a_missing_file
    with_repo do
      error = assert_raises(BreakCheck::Error) { BreakCheck::Breaks.load("nope.json") }
      assert_includes error.message, "nope.json"
    end
  end

  def test_problems_reports_every_break_not_just_the_first
    with_repo(FILES) do |root|
      problems = BreakCheck::Breaks.problems([brk(name: "one", to: "a > 1"), brk(name: "two", tests: [])], root:)
      assert_equal ["one: to is the same as from", "two: names no test file"], problems
    end
  end

  def test_load_and_problems_read_utf_8_whatever_the_locale
    with_repo(FILES.merge("lib/a.ex" => "a → b\n")) do |root|
      write("breaks.json", JSON.generate([{name: "arrow ⏎", file: "lib/a.ex", from: "a → b", to: "b", tests: ["test/a_test.exs"]}]))

      with_ascii_locale do
        breaks = BreakCheck::Breaks.load("breaks.json")
        assert_equal "arrow ⏎", breaks.first.name
        assert_equal [], BreakCheck::Breaks.problems(breaks, root:)
      end
    end
  end

  def test_occurrences_gives_the_line_each_match_starts_on
    assert_equal [2, 4], BreakCheck::Breaks.occurrences("a\nb\nc\nb\n", "b")
  end
end
