require_relative "test_helper"
require_relative "../break_check/workspace"
require "digest"
require "stringio"

class WorkspaceTest < Minitest::Test
  include RepoHelper

  SOURCE = "def x(a) when a > 1, do: :big\n"
  BROKEN = "def x(a) when a >= 1, do: :big\n"
  FILES = {"lib/a.ex" => SOURCE, "test/a_test.exs" => "test"}.freeze

  def test_lock_refuses_while_held
    with_repo(FILES) do |root|
      workspace(root).lock_and_recover do
        pid = fork do
          workspace(root).lock_and_recover {}
          exit!(0)
        rescue BreakCheck::Locked
          exit!(7)
        end
        Process.wait(pid)
        assert_equal 7, $?.exitstatus
      end
    end
  end

  def test_a_lock_held_by_a_dead_process_is_taken
    with_repo(FILES) do |root|
      pid = fork do
        workspace(root).lock_and_recover { exit!(0) }
      end
      Process.wait(pid)

      ran = false
      workspace(root).lock_and_recover { ran = true }
      assert ran
    end
  end

  def test_swap_writes_to_inside_the_block_and_restores_after
    with_repo(FILES) do |root|
      inside = nil
      workspace(root).swap(brk) { inside = File.read("lib/a.ex") }

      assert_equal BROKEN, inside
      assert_equal SOURCE, File.read("lib/a.ex")
      assert_empty Dir["#{root}/.breaks/journal/*"]
    end
  end

  def test_swap_and_recover_keep_utf_8_whatever_the_locale
    source = "a → b\n"
    with_repo(FILES.merge("lib/a.ex" => source)) do |root|
      with_ascii_locale do
        workspace(root).swap(brk(from: "a → b", to: "a ← b")) { assert_equal "a ← b\n", File.read("lib/a.ex", encoding: "UTF-8") }
        assert_equal source, File.read("lib/a.ex", encoding: "UTF-8")

        leave_journal(root, source, "a ← b\n")
        workspace(root).recover
        assert_equal source, File.read("lib/a.ex", encoding: "UTF-8")
      end
    end
  end

  def test_swap_restores_and_clears_its_journal_when_the_block_raises
    with_repo(FILES) do |root|
      assert_raises(Interrupt) { workspace(root).swap(brk) { raise Interrupt } }
      assert_equal SOURCE, File.read("lib/a.ex")
      assert_empty Dir["#{root}/.breaks/journal/*"]
    end
  end

  def test_swap_refuses_when_from_is_no_longer_exactly_once
    with_repo(FILES.merge("lib/a.ex" => SOURCE * 2)) do |root|
      assert_raises(BreakCheck::Error) { workspace(root).swap(brk) { flunk "ran" } }
      assert_equal SOURCE * 2, File.read("lib/a.ex")
    end
  end

  def test_swap_raises_restore_failed_and_keeps_its_journal_when_the_restore_fails
    with_repo(FILES) do |root|
      assert_raises(BreakCheck::RestoreFailed) do
        workspace(root).swap(brk) { File.chmod(0o444, "lib/a.ex") }
      end
      assert_equal 1, Dir["#{root}/.breaks/journal/*"].size
    ensure
      File.chmod(0o644, "lib/a.ex")
    end
  end

  def test_swap_leaves_a_file_edited_during_the_break_and_keeps_its_journal
    with_repo(FILES) do |root|
      assert_raises(BreakCheck::RestoreFailed) { workspace(root).swap(brk) { File.write("lib/a.ex", "saved meanwhile\n") } }

      assert_equal "saved meanwhile\n", File.read("lib/a.ex")
      assert_equal 1, Dir["#{root}/.breaks/journal/*"].size
    end
  end

  def test_recover_names_the_entry_whose_file_is_gone
    with_repo(FILES) do |root|
      leave_journal(root, SOURCE, BROKEN)
      File.delete("lib/a.ex")

      error = assert_raises(BreakCheck::RestoreFailed) { workspace(root).recover }
      assert_includes error.message, ".breaks/journal/1.json"
    end
  end

  def test_recover_names_an_entry_it_cannot_read
    with_repo(FILES) do |root|
      write("#{root}/.breaks/journal/1.json", "{cut sho")

      error = assert_raises(BreakCheck::RestoreFailed) { workspace(root).recover }
      assert_includes error.message, ".breaks/journal/1.json"
    end
  end

  def test_recover_restores_a_file_that_still_holds_the_break
    with_repo(FILES) do |root|
      leave_journal(root, SOURCE, BROKEN)

      assert_equal ["lib/a.ex"], workspace(root).recover
      assert_equal SOURCE, File.read("lib/a.ex")
      assert_empty Dir["#{root}/.breaks/journal/*"]
    end
  end

  def test_recover_leaves_a_file_edited_since_the_killed_run
    with_repo(FILES) do |root|
      leave_journal(root, SOURCE, BROKEN)
      File.write("lib/a.ex", "newer work\n")

      error = assert_raises(BreakCheck::RestoreFailed) { workspace(root).recover }
      assert_includes error.message, "lib/a.ex"
      assert_equal "newer work\n", File.read("lib/a.ex")
      assert_equal 1, Dir["#{root}/.breaks/journal/*"].size
    end
  end

  def test_recover_drops_an_entry_whose_file_was_never_broken
    with_repo(FILES) do |root|
      leave_journal(root, SOURCE, BROKEN)
      File.write("lib/a.ex", SOURCE)

      assert_equal [], workspace(root).recover
      assert_empty Dir["#{root}/.breaks/journal/*"]
    end
  end

  def test_lock_recovers_first_and_says_so_loudly
    with_repo(FILES) do |root|
      leave_journal(root, SOURCE, BROKEN)
      out = StringIO.new

      inside = nil
      workspace(root, out:).lock_and_recover { inside = File.read("lib/a.ex") }

      assert_equal SOURCE, inside
      assert_equal "RESTORED lib/a.ex FROM A KILLED RUN\n", out.string
    end
  end

  def test_lock_names_a_test_run_a_killed_run_left_behind
    with_repo(FILES) do |root|
      pid = Process.spawn("sleep", "30", pgroup: true)
      write("#{root}/.breaks/child", pid.to_s)
      out = StringIO.new

      workspace(root, out:).lock_and_recover {}

      assert_includes out.string, "kill -TERM -#{pid}"
      refute File.exist?("#{root}/.breaks/child")
    ensure
      Process.kill("-KILL", pid)
      Process.wait(pid)
    end
  end

  def test_lock_says_nothing_of_a_test_run_that_already_ended
    with_repo(FILES) do |root|
      pid = Process.spawn("true", pgroup: true)
      Process.wait(pid)
      write("#{root}/.breaks/child", pid.to_s)
      out = StringIO.new

      workspace(root, out:).lock_and_recover {}

      assert_equal "", out.string
      refute File.exist?("#{root}/.breaks/child")
    end
  end

  private

  def workspace(root, out: StringIO.new) = BreakCheck::Workspace.new(root, out:)

  # What a run killed in the middle of a break leaves behind.
  def leave_journal(root, original, broken)
    write("#{root}/.breaks/journal/1.json", JSON.generate(path: "lib/a.ex", content: original, broken: Digest::SHA256.hexdigest(broken)))
    File.write("lib/a.ex", broken)
  end
end
