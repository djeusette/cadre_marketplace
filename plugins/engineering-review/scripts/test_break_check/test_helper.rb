require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"
require_relative "../break_check/breaks"

module RepoHelper
  # Builds a temporary repository from `path => content` and runs the block
  # inside it, so every path in a test is relative, as in a real repo.
  def with_repo(files = {})
    Dir.mktmpdir("break_check") do |root|
      files.each { |path, content| write(File.join(root, path), content) }
      Dir.chdir(root) { yield root }
    end
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  # A shell whose locale is plain ASCII must not change how files are read.
  def with_ascii_locale
    previous = Encoding.default_external
    Encoding.default_external = Encoding::US_ASCII
    yield
  ensure
    Encoding.default_external = previous
  end

  # A break that tells the fake test command how to behave.
  def mode_break(mode, name: "mode #{mode}", file: "lib/a.ex", from: "mode=pass")
    brk(name:, file:, from:, to: from.sub("mode=pass", "mode=#{mode}"))
  end

  def write_breaks(breaks, path = "breaks.json")
    File.write(path, JSON.generate(breaks.map(&:to_h)))
    path
  end

  def brk(name: "a break", file: "lib/a.ex", from: "a > 1", to: "a >= 1", tests: ["test/a_test.exs"])
    BreakCheck::Break.new(name:, file:, from:, to:, tests:)
  end
end
