require "json"
require_relative "breaks"

module BreakCheck
  class Usage < Error; end

  # How a repo runs its tests, how to read their output, and where its
  # branches live. `name` is its key in .break-check.json, which each proof
  # it makes records. `failing_test` captures each failing test's name in its
  # first group; `noise` matches changed lines that hold no branch; a doc
  # block runs from a `doc_open` line to the next `doc_close` line.
  Profile = Data.define(:name, :command, :failing_test, :compile_error, :infrastructure, :refusal, :timeout,
    :watched, :noise, :doc_open, :doc_close)

  module Profiles
    SETTINGS = ".break-check.json"

    # Checks every profile in the file, so a broken one shows before it is
    # picked; the partition goes to the chosen one only.
    def self.load(root, name:, partition:)
      profiles, default = read(root)
      chosen = name || default
      raise Usage, "unknown profile #{chosen} (#{SETTINGS} has #{profiles.keys.join(", ")})" unless profiles.key?(chosen)

      build_all(root, profiles) { (partition if _1 == chosen) }.fetch(chosen)
    end

    # Every profile, and the name of the one a proof that records none
    # takes. The partition goes to each profile that names {partition}.
    def self.load_all(root, partition:)
      profiles, default = read(root)
      built = build_all(root, profiles) { nil }
      return [built, default] unless partition

      takers = profiles.select { |_, fields| takes_partition?(fields) }.keys
      raise Usage, "#{SETTINGS}: no profile takes --partition" if takers.empty?

      [built.merge(takers.to_h { [_1, build(_1, profiles[_1], partition:)] }), default]
    end

    # The profiles as the file holds them, and the default: the one it
    # names, or the only one.
    def self.read(root)
      path = File.join(root, SETTINGS)
      raise Usage, "no #{SETTINGS} in #{root}: run from the repository root, or write one (see contract.md)" unless File.file?(path)

      profiles, default = parse(path)
      [profiles, default || profiles.keys.first]
    end

    def self.build_all(root, profiles)
      built = profiles.to_h { |each_name, fields| [each_name, build(each_name, fields, partition: yield(each_name))] }
      built.each { |each_name, profile| check_watched(root, each_name, profile) }
    end

    def self.check_watched(root, name, profile)
      missing = profile.watched.find { !File.exist?(File.join(root, _1)) }
      refuse(name, "watched path #{missing} does not exist") if missing
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

      Profile.new(name:, command: command(name, fields, partition), timeout: fields["timeout"], watched: fields["watched"], **patterns)
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
      takes_partition = takes_partition?(fields)
      raise Usage, "#{SETTINGS}: profile #{name} takes no --partition" if partition && !takes_partition

      lambda do |files|
        raise Usage, "--partition N is required to run tests with #{name}" if takes_partition && !partition

        fill = ->(text) { text.gsub("{partition}", partition.to_s) }
        [env.transform_values(&fill), *argv.flat_map { _1 == "{files}" ? files : [fill.call(_1)] }]
      end
    end

    # Only for fields `check_values` has passed.
    def self.takes_partition?(fields) = [*fields["command"], *fields.fetch("env", {}).values].any? { _1.include?("{partition}") }

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
      raise Usage, "#{SETTINGS}: profiles must name at least one profile" unless settings.is_a?(Hash)

      unknown = settings.keys - %w[profiles default]
      raise Usage, "#{SETTINGS}: unknown key #{unknown.join(", ")}" if unknown.any?

      profiles = settings["profiles"]
      raise Usage, "#{SETTINGS}: profiles must name at least one profile" unless profiles.is_a?(Hash) && profiles.any?

      default = settings["default"]
      raise Usage, "#{SETTINGS}: default is required when there is more than one profile" if profiles.size > 1 && !default
      raise Usage, "#{SETTINGS}: default names no profile: #{default}" if default && !profiles.key?(default)

      [profiles, default]
    rescue JSON::ParserError => error
      raise Usage, "#{SETTINGS} is not JSON: #{error.message.lines.first.strip}"
    end
  end
end
