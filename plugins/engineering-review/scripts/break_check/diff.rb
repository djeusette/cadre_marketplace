require "open3"
require "set"
require_relative "breaks"

module BreakCheck
  # One hunk of a `git diff -U0`: the lines it adds, the text of the lines
  # it removes, and the new file's lines just above and below it (0 above
  # a hunk at the top of a file).
  Hunk = Data.define(:file, :added, :deleted, :above, :below) do
    # The lines a deletion sits between.
    def around = [above, below]
  end

  # What a change did since a base: its hunks, and every line of the files
  # git does not track yet.
  Change = Data.define(:hunks, :untracked) do
    def added = hunks.flat_map(&:added) + untracked

    # The lines a proof must span to belong to the change: each added line,
    # and the lines just above and below each hunk that deletes.
    def touched
      around = hunks.reject { _1.deleted.empty? }.flat_map { |hunk| hunk.around.map { [hunk.file, _1] } }
      added.map { [_1[:file], _1[:line]] }.to_set.merge(around)
    end
  end

  module Diff
    # The change since `base`, committed or not, limited to `paths`, or the
    # whole tree without them. A base git doesn't know raises Error.
    def self.since(root, base, paths = [])
      diff = git(root, "diff", "--no-color", "--no-ext-diff", "-M", "--src-prefix=a/", "--dst-prefix=b/", "-U0",
        "--end-of-options", base, "--", *paths)
      # -z: names come back as they are, never quoted.
      untracked = git(root, "ls-files", "-z", "--others", "--exclude-standard", "--", *paths).split("\0")
        .select { File.file?(File.join(root, _1)) }
      Change.new(hunks: parse(diff), untracked: untracked.flat_map { whole_file(root, _1) })
    end

    def self.whole_file(root, file)
      BreakCheck.read(File.join(root, file)).each_line(chomp: true).with_index(1).map { |text, line| {file:, line:, text:} }
    end

    # Paths come back as they are: no quoting of accented names.
    def self.git(root, *args)
      output, status = Open3.capture2e("git", "-c", "core.quotePath=false", *args, chdir: root)
      raise Error, "git #{args.first} failed: #{output.strip}" unless status.success?

      output.force_encoding(Encoding::UTF_8).scrub
    end

    # A file's `+++` header comes before its first hunk; inside a hunk,
    # every `+` or `-` line is code, even one that starts with `++` or
    # `--`. Git ends a header path holding a space with a tab, and names a
    # deleted file's new side /dev/null, whose hunks are left out. The runner
    # refuses a path git quotes (one holding `"`, `\` or a control
    # character), so its lines never read as unchanged.
    def self.parse(diff)
      hunks = []
      file = nil
      in_hunk = false
      diff.each_line(chomp: true) do |line|
        if line.start_with?("diff --git ")
          in_hunk = false
        elsif !in_hunk && line.start_with?("+++ ")
          file = new_path(line)
        elsif line =~ /\A@@ -\S+ \+(\d+)(?:,(\d+))? @@/
          in_hunk = true
          hunks << hunk(file, $1.to_i, ($2 || "1").to_i)
        elsif in_hunk && line.start_with?("+")
          hunks.last.added << {file:, line: hunks.last.above + 1 + hunks.last.added.size, text: line[1..]}
        elsif in_hunk && line.start_with?("-")
          hunks.last.deleted << line[1..]
        end
      end
      hunks.select(&:file)
    end

    def self.new_path(header)
      return if header == "+++ /dev/null"

      header[%r{\A\+\+\+ b/(.+?)\t?\z}, 1] or raise Error, "cannot read the path in git's diff header: #{header}"
    end

    # Git starts a hunk that adds no line at the line before it.
    def self.hunk(file, start, count)
      above = count.zero? ? start : start - 1
      Hunk.new(file:, added: [], deleted: [], above:, below: above + count + 1)
    end

    private_class_method :whole_file, :git, :parse, :new_path, :hunk
  end
end
