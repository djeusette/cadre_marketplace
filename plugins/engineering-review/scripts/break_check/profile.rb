require "rbconfig"
require_relative "breaks"

module BreakCheck
  class Usage < Error; end

  # How a repo runs its tests, how to read their output, and where its
  # branches live. `failing_test` captures each failing test's name in its
  # first group; `noise` matches changed lines that hold no branch; a doc
  # block runs from a `doc_open` line to the next `doc_close` line.
  Profile = Data.define(:command, :failing_test, :compile_error, :infrastructure, :refusal, :timeout,
    :watched, :noise, :doc_open, :doc_close)

  module Profiles
    # The partition is checked when a test runs, so commands that run none
    # (--uncovered, a replay with nothing stale) need no --partition.
    def self.exunit(partition:)
      Profile.new(
        # A fixed seed runs the tests in the same order as their baseline.
        command: lambda do |files|
          raise Usage, "--partition N is required to run tests with exunit" unless partition

          [{"MIX_TEST_PARTITION" => partition.to_s}, "mise", "exec", "--", "mix", "test", "--seed", "0", *files]
        end,
        failing_test: /^\s+\d+\) (test .+ \([\w.]+\))$/,
        compile_error: /== Compilation error in file/,
        infrastructure: /too_many_connections/,
        refusal: /Another mix test run is using/,
        timeout: 300,
        watched: %w[lib],
        noise: /\A\s*(?:#(?!\{).*|end|do|\)|\]|\}|)\s*\z/,
        doc_open: /\A\s*@(?:moduledoc|doc|typedoc)\s+"""\s*\z/,
        doc_close: /\A\s*"""\s*\z/
      )
    end

    # For the runner's own code in script/.
    def self.minitest
      Profile.new(
        command: ->(files) { [{}, RbConfig.ruby, "-e", "ARGV.each { require File.expand_path(_1) }", *files] },
        failing_test: /^\s+\d+\) (?:Failure|Error):\n(\S+#test_\w+)/,
        compile_error: /SyntaxError/,
        infrastructure: nil,
        refusal: nil,
        timeout: 120,
        watched: %w[script/break_check.rb script/break_check],
        noise: /\A\s*(?:#(?!\{).*|end|\)|\]|\}|)\s*\z/,
        doc_open: nil,
        doc_close: nil
      )
    end
  end
end
