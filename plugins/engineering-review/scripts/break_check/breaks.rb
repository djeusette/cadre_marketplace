require "json"

module BreakCheck
  class Error < StandardError; end

  # Every file the runner reads is UTF-8, whatever the shell's locale says.
  def self.read(path) = File.read(path, encoding: Encoding::UTF_8)

  # One deliberate break: swap `from` for `to` in `file`, then run `tests`.
  Break = Data.define(:name, :file, :from, :to, :tests)

  # Reads a breaks file and checks every swap before anything runs.
  module Breaks
    KEYS = %w[name file from to tests].freeze

    def self.load(path)
      entries = JSON.parse(BreakCheck.read(path))
      raise Error, "#{path}: a breaks file is a JSON array of breaks" unless entries.is_a?(Array)

      entries.map { |entry| to_break(entry) }
    rescue JSON::ParserError, SystemCallError => error
      raise Error, "cannot read breaks file #{path}: #{error.message.lines.first.strip}"
    end

    def self.to_break(entry)
      raise Error, "each break must be an object, got #{entry.inspect}" unless entry.is_a?(Hash)

      missing = KEYS - entry.keys
      raise Error, "#{entry["name"] || entry.inspect}: missing #{missing.join(", ")}" if missing.any?
      raise Error, "#{entry["name"]}: tests must be a list of paths" unless entry["tests"].is_a?(Array) && entry["tests"].all?(String)

      Break.new(**entry.slice(*KEYS).transform_keys(&:to_sym))
    end

    # The line number each match of `from` starts on.
    def self.occurrences(text, from)
      offsets = []
      offset = text.index(from)
      while offset
        offsets << offset
        offset = text.index(from, offset + 1)
      end
      offsets.map { |at| text[0, at].count("\n") + 1 }
    end

    # A name is a branch's identity in the ledger, so it is unique per file.
    def self.problems(breaks, root:)
      seen = Set.new
      breaks.flat_map do |brk|
        duplicate = ("another break in #{brk.file} has this name" unless seen.add?([brk.file, brk.name]))
        [*duplicate, *problems_of(brk, root)].map { |problem| "#{brk.name}: #{problem}" }
      end
    end

    def self.problems_of(brk, root)
      source = File.join(root, brk.file)
      return ["#{brk.file} does not exist"] unless File.file?(source)

      [
        *("to is the same as from" if brk.to == brk.from),
        *occurrence_problem(brk, BreakCheck.read(source)),
        *("names no test file" if brk.tests.empty?),
        *brk.tests.reject { |test| File.file?(File.join(root, test)) }.map { "test file #{_1} does not exist" }
      ]
    end

    def self.occurrence_problem(brk, text)
      lines = occurrences(text, brk.from)
      case lines.size
      when 1 then []
      when 0 then ["from not found in #{brk.file} (0 occurrences)"]
      else ["from not unique in #{brk.file} (#{lines.size} occurrences, lines #{lines.join(", ")})"]
      end
    end

    private_class_method :to_break, :problems_of, :occurrence_problem
  end
end
