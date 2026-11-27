require "digest"
require "fileutils"
require "json"
require "securerandom"
require_relative "breaks"

module BreakCheck
  class Locked < Error; end
  class RestoreFailed < Error; end

  # Where breaks happen: one runner at a time, every original journaled
  # before its swap, so a killed run is undone when the next one starts.
  class Workspace
    def initialize(root, out: $stdout)
      @root = root
      @out = out
      @dir = File.join(root, ".breaks")
      @journal = File.join(@dir, "journal")
      @child = File.join(@dir, "child")
    end

    # Takes the lock, then puts back whatever a killed run left broken, so
    # the block never reads a file that still holds a break. The OS drops a
    # flock when its process dies: a killed run never locks the next one out.
    def lock_and_recover
      FileUtils.mkdir_p(@dir)
      File.open(File.join(@dir, "lock"), File::RDWR | File::CREAT) do |file|
        raise Locked, "another break check is running in #{@root}" unless file.flock(File::LOCK_EX | File::LOCK_NB)

        name_left_child
        recover.each { @out.puts "RESTORED #{_1} FROM A KILLED RUN" }
        yield
      end
    end

    # Puts back each file a killed run left broken. A file that no longer
    # holds the break was edited since: it is left alone, with its entry.
    def recover
      Dir[File.join(@journal, "*.json")].sort.filter_map do |entry_path|
        entry = read_entry(entry_path)
        path = File.join(@root, entry["path"])
        current = BreakCheck.read(path)
        restored =
          if current == entry["content"]
            nil
          elsif Digest::SHA256.hexdigest(current) == entry["broken"]
            File.write(path, entry["content"])
            entry["path"]
          else
            raise RestoreFailed, changed(entry["path"], entry_path)
          end
        File.delete(entry_path)
        restored
      rescue SystemCallError => error
        raise RestoreFailed, "#{relative(entry_path)} names a file that cannot be read (#{error.message}); deal with it, then delete that entry"
      end
    end

    def swap(brk)
      path = File.join(@root, brk.file)
      original = BreakCheck.read(path)
      count = Breaks.occurrences(original, brk.from).size
      raise Error, "#{brk.name}: from occurs #{count} times in #{brk.file}, expected once" unless count == 1

      broken = original.sub(brk.from) { brk.to }
      entry_path = journal(brk.file, original, broken)
      begin
        File.write(path, broken)
        yield
      ensure
        restore(path, brk.file, original, broken, entry_path)
        File.delete(entry_path)
      end
    end

    # The test run in flight, so a run killed outright can name it.
    def track_child(pid)
      File.write(@child, pid.to_s)
      yield
    ensure
      FileUtils.rm_f(@child)
    end

    private

    # Written whole or not at all, so a kill mid-write leaves no half entry.
    def journal(file, original, broken)
      FileUtils.mkdir_p(@journal)
      entry_path = File.join(@journal, "#{SecureRandom.hex(8)}.json")
      File.write("#{entry_path}.tmp", JSON.generate(path: file, content: original, broken: Digest::SHA256.hexdigest(broken)))
      File.rename("#{entry_path}.tmp", entry_path)
      entry_path
    end

    def read_entry(entry_path)
      JSON.parse(BreakCheck.read(entry_path))
    rescue JSON::ParserError
      raise RestoreFailed, "#{relative(entry_path)} cannot be read; check the file it names, then delete it"
    end

    # Restores only a file that still holds the break: a save made while the
    # tests ran is kept, and so is the journal entry.
    def restore(path, file, original, broken, entry_path)
      raise RestoreFailed, changed(file, entry_path) unless Digest::SHA256.hexdigest(BreakCheck.read(path)) == Digest::SHA256.hexdigest(broken)

      File.write(path, original)
      raise RestoreFailed, "#{file} differs from its original after restore" unless BreakCheck.read(path) == original
    rescue SystemCallError => error
      raise RestoreFailed, "could not restore #{file}: #{error.message}; its original is in #{relative(entry_path)}"
    end

    def changed(file, entry_path)
      "#{file} changed while it held a break; compare it with the original in #{relative(entry_path)}, then delete that file"
    end

    def relative(path) = path.delete_prefix("#{@root}/")

    # A pid can be reused, so a left test run is named, never killed.
    def name_left_child
      return unless File.file?(@child)

      pid = BreakCheck.read(@child).to_i
      Process.kill(0, -pid)
      @out.puts "A test run left by a killed break check may still be running; stop it with: kill -TERM -#{pid}"
    rescue Errno::ESRCH, Errno::EPERM
      nil
    ensure
      FileUtils.rm_f(@child)
    end
  end
end
