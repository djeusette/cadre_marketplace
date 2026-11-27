require "digest"
require "fileutils"
require "json"
require_relative "breaks"

module BreakCheck
  # The proof: one line per caught break, written only by the runner, with
  # the hashes that tell a later step whether the proof still holds.
  class Ledger
    def initialize(root)
      @root = root
      @path = File.join(root, ".breaks", "ledger.jsonl")
    end

    def self.to_break(entry)
      Break.new(name: entry["name"], file: entry["file"], from: entry["from"], to: entry["to"],
        tests: test_files(entry))
    end

    # The test files a proof ran: every hashed file but its source.
    def self.test_files(entry) = entry["hashes"].keys - [entry["file"]]

    def entries
      return [] unless File.file?(@path)

      BreakCheck.read(@path).lines(chomp: true).reject(&:empty?).map { JSON.parse(_1) }
    end

    def record(brk, line:, tests_failed:, profile:)
      entry = {
        "name" => brk.name, "file" => brk.file, "line" => line, "from" => brk.from, "to" => brk.to,
        "tests_failed" => tests_failed, "hashes" => hashes([brk.file, *brk.tests]), "profile" => profile
      }
      kept = entries.reject { same_swap?(_1, brk) || (same_name?(_1, brk) && !fresh?(_1)) }
      write(kept + [entry])
    end

    # A name is a branch's identity in its file, so a new break may take
    # a name only from a proof that is not fresh, whose new proof then
    # replaces it.
    def name_conflicts(breaks)
      breaks.filter_map do |brk|
        next unless entries.any? { same_name?(_1, brk) && !same_swap?(_1, brk) && fresh?(_1) }

        "#{brk.name}: a proof in #{brk.file} already has this name"
      end
    end

    # Replayable proofs rerun from the ledger as they are; gone ones need a
    # new break: their `from` moved, or one of their test files is gone.
    def stale
      stale_entries = entries.reject { fresh?(_1) }
      replayable, gone = stale_entries.partition { once?(_1) && tests_exist?(_1) }
      {replayable:, gone:}
    end

    def drop(dropped)
      write(entries - dropped)
    end

    def fresh_entries = entries.select { fresh?(_1) }

    # The fresh proof of this exact break, if there is one.
    def proof(brk) = fresh_entries.find { same_swap?(_1, brk) }

    def table
      fresh = fresh_entries
      rows = fresh.map do |entry|
        swap = "#{code(entry["from"])} → #{code(entry["to"])}"
        "| #{entry["file"]}:#{entry["line"]} | #{swap} | #{cell(entry["tests_failed"].join(", "))} |"
      end
      <<~MARKDOWN
        <details><summary>Break checks (#{fresh.size})</summary>

        | Branch | Swap | Caught by |
        |---|---|---|
        #{rows.join("\n")}

        </details>
      MARKDOWN
    end

    private

    def fresh?(entry) = entry["hashes"] == hashes(entry["hashes"].keys) && once?(entry)

    def same_swap?(entry, brk) = entry["file"] == brk.file && entry["from"] == brk.from && entry["to"] == brk.to

    def same_name?(entry, brk) = entry["file"] == brk.file && entry["name"] == brk.name

    def tests_exist?(entry) = Ledger.test_files(entry).all? { File.file?(File.join(@root, _1)) }

    def once?(entry)
      path = File.join(@root, entry["file"])
      File.file?(path) && Breaks.occurrences(BreakCheck.read(path), entry["from"]).size == 1
    end

    def hashes(paths)
      paths.to_h do |path|
        full = File.join(@root, path)
        [path, File.file?(full) ? Digest::SHA256.file(full).hexdigest : nil]
      end
    end

    # A fence longer than any run of backticks inside, padded with the one
    # space on each side that Markdown strips, so a backtick at either end
    # stays code.
    def code(text)
      return "`#{cell(text)}`" unless text.include?("`")

      fence = "`" * (text.scan(/`+/).map(&:size).max + 1)
      "#{fence} #{cell(text)} #{fence}"
    end

    def cell(text) = text.gsub("|", "\\|").gsub("\n", "⏎")

    def write(all)
      FileUtils.mkdir_p(File.dirname(@path))
      temp = "#{@path}.tmp"
      File.write(temp, all.map { JSON.generate(_1) + "\n" }.join)
      File.rename(temp, @path)
    end
  end
end
