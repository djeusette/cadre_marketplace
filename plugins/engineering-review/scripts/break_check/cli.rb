# Every runner file is required here, before any break: a break in the
# runner's own code never loads into the running runner.
require "optparse"
require_relative "breaks"
require_relative "ledger"
require_relative "profile"
require_relative "run"
require_relative "uncovered"
require_relative "workspace"

module BreakCheck
  module CLI
    COMMANDS = %i[breaks stale uncovered table].freeze

    BANNER = <<~TEXT
      Usage: ruby break_check.rb BREAKS.json [--profile NAME] [--partition N]  break each branch, record what is caught
             ruby break_check.rb --stale [--replay [--partition N]]            list stale proofs, or rerun them
             ruby break_check.rb --uncovered BASE                              changed lines since BASE with no fresh proof
             ruby break_check.rb --table                                       the ledger as the PR's table
      Run from the repository root; profiles come from its .break-check.json, and
      --profile NAME, on any command, picks one other than its default.
    TEXT

    # Prints as it goes, so a run killed midway still shows its results.
    # Returns the exit code.
    def self.run(argv, out: $stdout)
      dispatch(parse(argv), out)
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
      options = {}
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

    # Every command reads .break-check.json first, so a run outside a
    # repository's root never reads as an all-clear.
    def self.dispatch(options, out)
      raise Usage, BANNER unless COMMANDS.any? { options[_1] }

      profile = Profiles.load(Dir.pwd, name: options[:profile], partition: options[:partition])
      ledger = Ledger.new(Dir.pwd)
      workspace = Workspace.new(Dir.pwd, out:)

      if options[:table]
        workspace.lock_and_recover { out.print ledger.table }
        0
      elsif options[:uncovered]
        uncovered = Uncovered.new(Dir.pwd, profile)
        workspace.lock_and_recover { print_uncovered(uncovered.call(options[:uncovered]), out) }
      elsif options[:stale] && options[:replay]
        replay(ledger, workspace, profile, out)
      elsif options[:stale]
        workspace.lock_and_recover { print_stale(ledger.stale, out) }
      else
        exit_code(Run.new(profile:, out:).call(Breaks.load(options[:breaks])))
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

    def self.exit_code(outcomes) = outcomes.all? { _1.result == :caught } ? 0 : 1
  end
end
