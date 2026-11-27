require "set"
require_relative "breaks"
require_relative "diff"
require_relative "ledger"

module BreakCheck
  # The changed lines no fresh proof covers yet: what is left to break. The
  # profile says where branches live and which lines hold none.
  class Uncovered
    def initialize(root, profile)
      @root = root
      @profile = profile
      @ledger = Ledger.new(root)
    end

    # The added lines, and one line per deletion, at the line now after it.
    def call(base)
      change = Diff.since(@root, base, @profile.watched)
      covered = covered_lines
      added = change.added.reject { |line| covered.include?([line[:file], line[:line]]) || blank?(line) }
      deletions = change.hunks.filter_map { deletion(_1, covered) }
      (added + deletions).sort_by { [_1[:file], _1[:line]] }
    end

    private

    # A line that holds no branch: noise, or inside a doc block.
    def blank?(line) = line[:text].match?(@profile.noise) || doc_lines(line[:file]).include?(line[:line])

    # A hunk that deletes a line holding a branch and adds none, as the
    # line now just after it; a fresh proof on either line around it
    # covers it.
    def deletion(hunk, covered)
      return if hunk.added.any? { !blank?(_1) }
      return if [hunk.above, hunk.below].any? { covered.include?([hunk.file, _1]) }

      inside, = doc_scan(lines_of(hunk.file).first(hunk.above))
      _, docs = doc_scan(hunk.deleted, inside:)
      text = hunk.deleted.each_with_index.find { |deleted, index| !docs[index] && !deleted.match?(@profile.noise) }&.first
      {file: hunk.file, line: hunk.below, text: "(deleted) #{text}"} if text
    end

    # The numbers of the lines of `file` inside a doc block, its opening
    # and closing lines included.
    def doc_lines(file)
      @doc_lines ||= Hash.new do |cache, path|
        _, docs = doc_scan(lines_of(path))
        cache[path] = docs.each_index.select { docs[_1] }.map { _1 + 1 }.to_set
      end
      @doc_lines[file]
    end

    # Whether a doc block is still open after `lines`, and which of them
    # sit in one, given whether one was open before the first.
    def doc_scan(lines, inside: false)
      return [false, lines.map { false }] unless @profile.doc_open

      docs = lines.map do |text|
        inside ||= text.match?(@profile.doc_open)
        next false unless inside

        inside = !text.match?(@profile.doc_close)
        true
      end
      [inside, docs]
    end

    def lines_of(file) = BreakCheck.read(File.join(@root, file)).lines(chomp: true)

    def covered_lines
      @ledger.fresh_entries.flat_map { |entry| @ledger.span(entry).map { [entry["file"], _1] } }.to_set
    end
  end
end
