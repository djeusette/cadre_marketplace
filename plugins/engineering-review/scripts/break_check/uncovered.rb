require "open3"
require_relative "breaks"
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

    def call(base)
      added = added_lines(base)
      skipped = covered_lines | doc_lines(added.map { _1[:file] }.uniq)
      added.reject { |line| skipped.include?([line[:file], line[:line]]) || line[:text].match?(@profile.noise) }
    end

    private

    # Every line of a doc block, its opening and closing lines included.
    def doc_lines(files)
      return Set.new unless @profile.doc_open

      files.flat_map do |file|
        inside = false
        BreakCheck.read(File.join(@root, file)).each_line(chomp: true).with_index(1).filter_map do |text, number|
          inside = true if text.match?(@profile.doc_open)
          next unless inside

          inside = false if text.match?(@profile.doc_close)
          [file, number]
        end
      end.to_set
    end

    def covered_lines
      @ledger.fresh_entries.flat_map do |entry|
        start = Breaks.occurrences(BreakCheck.read(File.join(@root, entry["file"])), entry["from"]).first
        (start..start + entry["from"].count("\n")).map { [entry["file"], _1] }
      end.to_set
    end

    # Lines added since `base`, committed or not, and every line of a new
    # file not yet added to git.
    def added_lines(base)
      diff = git("diff", "--no-color", "--no-ext-diff", "-M", "--src-prefix=a/", "--dst-prefix=b/", "-U0", base, "--", *@profile.watched)
      untracked = git("ls-files", "--others", "--exclude-standard", "--", *@profile.watched).lines(chomp: true)
      parse(diff) + untracked.flat_map { |file| whole_file(file) }
    end

    def whole_file(file)
      BreakCheck.read(File.join(@root, file)).each_line(chomp: true).with_index(1).map { |text, line| {file:, line:, text:} }
    end

    # Paths come back as they are: no quoting of accented names.
    def git(*args)
      output, status = Open3.capture2e("git", "-c", "core.quotePath=false", *args, chdir: @root)
      raise Error, "git #{args.first} failed: #{output.strip}" unless status.success?

      output.force_encoding(Encoding::UTF_8).scrub
    end

    # A file's `+++` header comes before its first hunk; inside a hunk,
    # every `+` line is code, even one that starts with `++`. Git ends a
    # header path holding a space with a tab.
    def parse(diff)
      added = []
      file = nil
      number = nil
      in_hunk = false
      diff.each_line(chomp: true) do |line|
        if line.start_with?("diff --git ")
          in_hunk = false
        elsif !in_hunk && line.start_with?("+++ ")
          file = line[%r{\A\+\+\+ b/(.+?)\t?\z}, 1]
        elsif line =~ /\A@@ -\S+ \+(\d+)/
          in_hunk = true
          number = $1.to_i
        elsif line.start_with?("+")
          added << {file:, line: number, text: line[1..]}
          number += 1
        end
      end
      added
    end
  end
end
