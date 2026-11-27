require "json"
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
    SETTINGS = ".break-check.json"

    def self.load(root, name:, partition:)
      path = File.join(root, SETTINGS)
      raise Usage, "no #{SETTINGS} in #{root}: run from the repository root, or write one (see contract.md)" unless File.file?(path)

      profiles, default = parse(path)
      chosen = name || default || profiles.keys.first
      fields = profiles.fetch(chosen) { raise Usage, "unknown profile #{chosen} (#{SETTINGS} has #{profiles.keys.join(", ")})" }
      build(chosen, fields, partition:).tap do |profile|
        missing = profile.watched.find { !File.exist?(File.join(root, _1)) }
        refuse(chosen, "watched path #{missing} does not exist") if missing
      end
    end

    REQUIRED = %w[command failing_test compile_error timeout watched noise].freeze
    OPTIONAL = %w[env infrastructure refusal doc_open doc_close].freeze
    PATTERNS = %w[failing_test compile_error infrastructure refusal noise doc_open doc_close].freeze

    # A profile's fields as .break-check.json holds them, checked.
    def self.build(name, fields, partition:)
      check_keys(name, fields)
      check_values(name, fields)
      patterns = PATTERNS.to_h { [_1.to_sym, pattern(name, _1, fields[_1])] }
      refuse(name, "failing_test needs a group that captures the test's name") if groups(patterns[:failing_test]).zero?
      refuse(name, "doc_open and doc_close come together") if patterns[:doc_open].nil? != patterns[:doc_close].nil?

      Profile.new(command: command(name, fields, partition), timeout: fields["timeout"], watched: fields["watched"], **patterns)
    end

    def self.check_keys(name, fields)
      refuse(name, "must be an object") unless fields.is_a?(Hash)
      missing = REQUIRED - fields.keys
      refuse(name, "missing #{missing.join(", ")}") if missing.any?
      unknown = fields.keys - REQUIRED - OPTIONAL
      refuse(name, "unknown key #{unknown.join(", ")}") if unknown.any?
    end

    # `{files}` stands alone after the program: a command of one string
    # would run through the shell.
    def self.check_values(name, fields)
      command = fields["command"]
      unless strings?(command) && command.count("{files}") == 1 && command.first != "{files}"
        refuse(name, "command must be a list of strings holding {files} once, as a whole argument after the program")
      end
      env = fields.fetch("env", {})
      refuse(name, "env must map names to strings") unless env.is_a?(Hash) && env.values.all?(String)
      timeout = fields["timeout"]
      refuse(name, "timeout must be a positive number of seconds") unless timeout.is_a?(Numeric) && timeout.positive?
      refuse(name, "watched must be a list of paths") unless strings?(fields["watched"]) && fields["watched"].any?
    end

    def self.strings?(value) = value.is_a?(Array) && value.all?(String)

    # The partition is checked when a test runs, so commands that run none
    # (--uncovered, a replay with nothing stale) need no --partition.
    def self.command(name, fields, partition)
      env = fields.fetch("env", {})
      argv = fields["command"]
      takes_partition = [*argv, *env.values].any? { _1.include?("{partition}") }
      raise Usage, "#{SETTINGS}: profile #{name} takes no --partition" if partition && !takes_partition

      lambda do |files|
        raise Usage, "--partition N is required to run tests with #{name}" if takes_partition && !partition

        fill = ->(text) { text.gsub("{partition}", partition.to_s) }
        [env.transform_values(&fill), *argv.flat_map { _1 == "{files}" ? files : [fill.call(_1)] }]
      end
    end

    # Flags go inline, as in `(?m)`.
    def self.pattern(name, key, source)
      return if source.nil?
      refuse(name, "#{key} is not a valid pattern: it must be a string") unless source.is_a?(String)

      Regexp.new(source)
    rescue RegexpError => error
      refuse(name, "#{key} is not a valid pattern: #{error.message}")
    end

    # The capturing groups in `regexp`: an empty alternative matches "",
    # and every group comes back nil.
    def self.groups(regexp) = Regexp.new("#{regexp.source}|").match("").captures.size

    def self.refuse(name, problem) = raise(Usage, "#{SETTINGS}: profile #{name}: #{problem}")

    # The profiles and the default, once the file's shape is checked.
    def self.parse(path)
      settings = JSON.parse(BreakCheck.read(path))
      profiles = settings["profiles"] if settings.is_a?(Hash)
      raise Usage, "#{SETTINGS}: profiles must name at least one profile" unless profiles.is_a?(Hash) && profiles.any?

      unknown = settings.keys - %w[profiles default]
      raise Usage, "#{SETTINGS}: unknown key #{unknown.join(", ")}" if unknown.any?

      default = settings["default"]
      raise Usage, "#{SETTINGS}: default is required when there is more than one profile" if profiles.size > 1 && !default
      raise Usage, "#{SETTINGS}: default names no profile: #{default}" if default && !profiles.key?(default)

      [profiles, default]
    rescue JSON::ParserError => error
      raise Usage, "#{SETTINGS} is not JSON: #{error.message.lines.first.strip}"
    end
  end
end
