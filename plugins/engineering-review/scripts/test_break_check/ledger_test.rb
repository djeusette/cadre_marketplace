require_relative "test_helper"
require_relative "../break_check/ledger"
require "digest"

class LedgerTest < Minitest::Test
  include RepoHelper

  SOURCE = "def x(a) when a > 1, do: :big\n"
  FILES = {"lib/a.ex" => SOURCE, "test/a_test.exs" => "test"}.freeze

  def test_record_writes_the_fields
    with_repo(FILES) do |root|
      ledger = BreakCheck::Ledger.new(root)
      ledger.record(brk, line: 1, tests_failed: ["test big (ATest)"])

      ledger.entries => [entry]
      assert_equal %w[name file line from to tests_failed hashes].sort, entry.keys.sort
      assert_equal 1, entry["line"]
      assert_equal ["test big (ATest)"], entry["tests_failed"]
      assert_equal({"lib/a.ex" => Digest::SHA256.hexdigest(SOURCE), "test/a_test.exs" => Digest::SHA256.hexdigest("test")},
        entry["hashes"])
    end
  end

  def test_record_replaces_the_proof_of_the_same_swap
    with_repo(FILES) do |root|
      ledger = BreakCheck::Ledger.new(root)
      ledger.record(brk(name: "first"), line: 1, tests_failed: ["t"])
      ledger.record(brk(name: "second"), line: 1, tests_failed: ["t"])

      assert_equal ["second"], ledger.entries.map { _1["name"] }
    end
  end

  def test_record_keeps_two_swaps_on_one_from
    with_repo(FILES) do |root|
      ledger = BreakCheck::Ledger.new(root)
      ledger.record(brk(name: "drop the guard value", to: "a >= 1"), line: 1, tests_failed: ["t"])
      ledger.record(brk(name: "flip the guard", to: "a < 1"), line: 1, tests_failed: ["t"])

      assert_equal ["a >= 1", "a < 1"], ledger.entries.map { _1["to"] }
    end
  end

  def test_record_replaces_a_gone_line_with_the_same_file_and_name
    with_repo(FILES) do |root|
      ledger = recorded(root)
      File.write("lib/a.ex", "def x(b) when b > 1, do: :big\n")
      ledger.record(brk(from: "b > 1", to: "b >= 1"), line: 1, tests_failed: ["t"])

      assert_equal ["b > 1"], ledger.entries.map { _1["from"] }
      assert_equal({replayable: [], gone: []}, ledger.stale)
    end
  end

  def test_record_replaces_a_same_name_line_only_when_it_is_gone
    with_repo(FILES.merge("lib/a.ex" => "a > 1\nb > 1\n")) do |root|
      ledger = BreakCheck::Ledger.new(root)
      ledger.record(brk(name: "guard", from: "a > 1"), line: 1, tests_failed: ["t"])
      ledger.record(brk(name: "guard", from: "b > 1", to: "b >= 1"), line: 2, tests_failed: ["t"])

      assert_equal ["a > 1", "b > 1"], ledger.entries.map { _1["from"] }
    end
  end

  def test_a_missing_test_file_makes_the_entry_gone
    with_repo(FILES) do |root|
      ledger = recorded(root)
      File.delete("test/a_test.exs")

      assert_equal({replayable: [], gone: ["a break"]}, names(ledger.stale))
    end
  end

  def test_drop_removes_the_given_entries
    with_repo(FILES.merge("lib/b.ex" => "b && c\n")) do |root|
      ledger = recorded(root)
      ledger.record(brk(name: "other", file: "lib/b.ex", from: "b && c", to: "b || c"), line: 1, tests_failed: ["t"])

      ledger.drop(ledger.entries.select { _1["name"] == "other" })

      assert_equal ["a break"], ledger.entries.map { _1["name"] }
    end
  end

  def test_an_untouched_entry_is_fresh
    with_repo(FILES) do |root|
      ledger = recorded(root)
      assert_equal({replayable: [], gone: []}, ledger.stale)
    end
  end

  def test_an_edited_source_file_makes_the_entry_replayable
    with_repo(FILES) do |root|
      ledger = recorded(root)
      File.write("lib/a.ex", SOURCE + "def y, do: 1\n")

      assert_equal({replayable: ["a break"], gone: []}, names(ledger.stale))
    end
  end

  def test_an_edited_test_file_makes_the_entry_replayable
    with_repo(FILES) do |root|
      ledger = recorded(root)
      File.write("test/a_test.exs", "test, edited")

      assert_equal({replayable: ["a break"], gone: []}, names(ledger.stale))
    end
  end

  def test_a_from_that_is_gone_makes_the_entry_gone
    with_repo(FILES) do |root|
      ledger = recorded(root)
      File.write("lib/a.ex", "def x(a) when a > 2, do: :big\n")

      assert_equal({replayable: [], gone: ["a break"]}, names(ledger.stale))
    end
  end

  def test_a_from_now_found_twice_makes_the_entry_gone
    with_repo(FILES) do |root|
      ledger = recorded(root)
      File.write("lib/a.ex", SOURCE * 2)

      assert_equal({replayable: [], gone: ["a break"]}, names(ledger.stale))
    end
  end

  def test_to_break_gives_back_the_tests
    with_repo(FILES) do |root|
      recorded(root).entries => [entry]
      assert_equal brk, BreakCheck::Ledger.to_break(entry)
    end
  end

  def test_table_lists_only_fresh_entries
    with_repo(FILES.merge("lib/b.ex" => "b && c\n")) do |root|
      ledger = recorded(root)
      ledger.record(brk(name: "other", file: "lib/b.ex", from: "b && c", to: "b || c"), line: 1, tests_failed: ["t"])
      File.write("lib/b.ex", "b && c\nmore\n")

      table = ledger.table
      assert_includes table, "<summary>Break checks (1)</summary>\n\n| Branch | Swap | Caught by |"
      assert_includes table, "| lib/a.ex:1 | `a > 1` → `a >= 1` | test big (ATest) |"
      refute_includes table, "lib/b.ex"
      assert table.end_with?("\n\n</details>\n")
    end
  end

  def test_table_escapes_pipes_and_newlines
    with_repo(FILES.merge("lib/b.ex" => "a |> b\nc\n")) do |root|
      ledger = BreakCheck::Ledger.new(root)
      ledger.record(brk(file: "lib/b.ex", from: "a |> b\nc", to: "a"), line: 1, tests_failed: ["t"])

      assert_includes ledger.table, "`a \\|> b⏎c`"
    end
  end

  def test_record_stale_and_table_read_utf_8_whatever_the_locale
    with_repo(FILES.merge("lib/b.ex" => "a → b\n")) do |root|
      with_ascii_locale do
        ledger = BreakCheck::Ledger.new(root)
        ledger.record(brk(name: "arrow", file: "lib/b.ex", from: "a → b", to: "b"), line: 1, tests_failed: ["t ⏎"])

        assert_equal({replayable: [], gone: []}, ledger.stale)
        assert_includes ledger.table, "`a → b` → `b` | t ⏎ |"
      end
    end
  end

  private

  def recorded(root)
    BreakCheck::Ledger.new(root).tap { _1.record(brk, line: 1, tests_failed: ["test big (ATest)"]) }
  end

  def names(stale) = stale.transform_values { |entries| entries.map { _1["name"] } }
end
