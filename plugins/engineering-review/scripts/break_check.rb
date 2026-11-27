#!/usr/bin/env ruby
# Breaks branches one at a time and records which test caught each one.
# See script/README.md.
#
# Every runner file is required here, before any break: a break in the
# runner's own code never loads into the running runner.
require "optparse"
require_relative "break_check/breaks"
require_relative "break_check/ledger"
require_relative "break_check/profile"
require_relative "break_check/run"
require_relative "break_check/uncovered"
require_relative "break_check/workspace"

module BreakCheck
  module CLI
    PROFILES = {
      "exunit" => ->(options) { Profiles.exunit(partition: options[:partition]) },
      "minitest" => ->(_options) { Profiles.minitest }
    }.freeze

    COMMANDS = %i[breaks stale uncovered table].freeze

    BANNER = <<~TEXT
      Usage: ruby script/break_check.rb BREAKS.json --partition N        break each branch, record what is caught
             ruby script/break_check.rb BREAKS.json --profile minitest   the runner's own tests
             ruby script/break_check.rb --stale [--replay --partition N] list stale proofs, or rerun them
             ruby script/break_check.rb --uncovered BASE                 changed lines since BASE with no fresh proof
             ruby script/break_check.rb --table                          the ledger as the PR's table
    TEXT

    # Prints as it goes, so a run killed midway still shows its results.
    # Returns the exit code.
    def self.run(argv, profiles: PROFILES, out: $stdout)
      dispatch(parse(argv), profiles, out)
    rescue RestoreFailed => error
      out.puts "RESTORE FAILED: #{error.message}"
      3
    rescue Error, OptionParser::ParseError => error
      out.puts error.message
      2
    rescue StandardError => error
      out.puts "unexpected error: #{error.class}: #{error.message}"
      2
    end

    def self.parse(argv)
      options = {profile: "exunit"}
      rest = OptionParser.new(BANNER) do |parser|
        parser.on("--partition N", Integer) { options[:partition] = _1 }
        parser.on("--profile NAME") { options[:profile] = _1 }
        parser.on("--stale") { options[:stale] = true }
        parser.on("--replay") { options[:replay] = true }
        parser.on("--table") { options[:table] = true }
        parser.on("--uncovered BASE") { options[:uncovered] = _1 }
      end.parse(argv)
      raise Usage, "one breaks file at a time" if rest.size > 1
      raise Usage, "--replay goes with --stale" if options[:replay] && !options[:stale]

      options.merge(breaks: rest.first).tap do |parsed|
        raise Usage, "one command at a time" if COMMANDS.count { parsed[_1] } > 1
      end
    end

    def self.dispatch(options, profiles, out)
      ledger = Ledger.new(Dir.pwd)
      workspace = Workspace.new(Dir.pwd, out:)

      if options[:table]
        workspace.lock_and_recover { out.print ledger.table }
        0
      elsif options[:uncovered]
        uncovered = Uncovered.new(Dir.pwd, profile(options, profiles))
        workspace.lock_and_recover { print_uncovered(uncovered.call(options[:uncovered]), out) }
      elsif options[:stale] && options[:replay]
        replay(ledger, workspace, profile(options, profiles), out)
      elsif options[:stale]
        workspace.lock_and_recover { print_stale(ledger.stale, out) }
      elsif options[:breaks]
        breaks = Breaks.load(options[:breaks])
        exit_code(Run.new(profile: profile(options, profiles), out:).call(breaks))
      else
        raise Usage, BANNER
      end
    end

    # Gone proofs are named first and dropped only once the replay has run,
    # so a replay that cannot run loses nothing. Their branches show up
    # again in --uncovered.
    def self.replay(ledger, workspace, profile, out)
      stale = workspace.lock_and_recover { ledger.stale }
      stale[:gone].each { out.puts "gone #{_1["file"]}:#{_1["line"]} #{_1["name"]}" }
      outcomes = stale[:replayable].any? ? Run.new(profile:, out:).call(stale[:replayable].map { Ledger.to_break(_1) }) : []
      return exit_code(outcomes) if stale[:gone].empty?

      workspace.lock_and_recover { ledger.drop(stale[:gone]) }
      out.puts "#{stale[:gone].size} gone #{(stale[:gone].size == 1) ? "proof" : "proofs"} dropped"
      1
    end

    def self.print_uncovered(lines, out)
      lines.each { out.puts "#{_1[:file]}:#{_1[:line]} | #{_1[:text]}" }
      out.puts "#{lines.size} changed lines have no fresh proof"
      lines.empty? ? 0 : 1
    end

    def self.print_stale(stale, out)
      stale.each { |kind, entries| entries.each { out.puts "#{kind} #{_1["file"]}:#{_1["line"]} #{_1["name"]}" } }
      count = stale.values.sum(&:size)
      out.puts "#{count} stale"
      count.zero? ? 0 : 1
    end

    def self.profile(options, profiles)
      profiles.fetch(options[:profile]) { raise Usage, "unknown profile #{options[:profile]}" }.call(options)
    end

    def self.exit_code(outcomes) = outcomes.all? { _1.result == :caught } ? 0 : 1
  end
end

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true
  exit BreakCheck::CLI.run(ARGV)
end
