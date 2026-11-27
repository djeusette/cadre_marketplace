require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"
require_relative "../break_check/breaks"

module RepoHelper
  # cadre's two profiles, as a .break-check.json holds them.
  EXUNIT = {
    "command" => ["mise", "exec", "--", "mix", "test", "--seed", "0", "{files}"],
    "env" => {"MIX_TEST_PARTITION" => "{partition}"},
    "failing_test" => '^\s+\d+\) (test .+ \([\w.]+\))$',
    "compile_error" => "== Compilation error in file",
    "infrastructure" => "too_many_connections",
    "refusal" => "Another mix test run is using",
    "timeout" => 300,
    "watched" => ["lib"],
    "noise" => '\A\s*(?:#(?!\{).*|end|do|\)|\]|\}|)\s*\z',
    "doc_open" => '\A\s*@(?:moduledoc|doc|typedoc)\s+"""\s*\z',
    "doc_close" => '\A\s*"""\s*\z'
  }.freeze

  MINITEST = {
    "command" => ["ruby", "-e", "ARGV.each { require File.expand_path(_1) }", "{files}"],
    "failing_test" => '^\s+\d+\) (?:Failure|Error):\n(\S+#test_\w+)',
    "compile_error" => "SyntaxError",
    "timeout" => 120,
    "watched" => ["script/break_check.rb", "script/break_check"],
    "noise" => '\A\s*(?:#(?!\{).*|end|\)|\]|\}|)\s*\z'
  }.freeze

  # The text of a .break-check.json holding `profiles`.
  def self.settings(profiles, default: nil)
    JSON.generate({"profiles" => profiles, "default" => default}.compact)
  end

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
