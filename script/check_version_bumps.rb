#!/usr/bin/env ruby
# Fails when a plugin changed since <base> without its version going up.
#
#   ruby script/check_version_bumps.rb <base>
#
# A plugin is changed when `git diff <base>...HEAD` touches a file under
# plugins/<name>/. Each one whose .claude-plugin/plugin.json is still there at
# HEAD needs a version there above the base's, or any version when the base
# has none. Prints OK and exits 0, or one line per plugin that fails and
# exits 1. A git failure, such as an unknown base, exits 2.

require "json"
require "open3"

USAGE = "Usage: ruby script/check_version_bumps.rb <base>".freeze
MANIFEST = ".claude-plugin/plugin.json".freeze

def stop(message)
  warn message
  exit 2
end

def git(*args)
  out, err, status = Open3.capture3("git", *args)
  stop(err) unless status.success?
  out.force_encoding("UTF-8")
end

def plugin_json(rev, name)
  out, _err, status = Open3.capture3("git", "show", "#{rev}:plugins/#{name}/#{MANIFEST}")
  JSON.parse(out.force_encoding("UTF-8")) if status.success?
end

def version_number?(version) = !version.to_s.empty? && Gem::Version.correct?(version.to_s)

def problem(base, name)
  head = plugin_json("HEAD", name) or return
  version = head["version"]
  return "plugins/#{name} has no version in #{MANIFEST}" unless version
  return "plugins/#{name} has version #{version.to_s.inspect} in #{MANIFEST}, which is not a version number" unless version_number?(version)

  old = plugin_json(base, name)&.dig("version")
  return unless version_number?(old) && Gem::Version.new(version) <= Gem::Version.new(old)

  "plugins/#{name} changed but its version #{version} is not above #{old}"
end

stop(USAGE) if ARGV.empty?
base = ARGV.first
paths = git("diff", "--name-only", "--no-renames", "-z", "#{base}...HEAD", "--", "plugins/").split("\0")
failures = paths.map { |path| path.split("/")[1] }.uniq.sort.filter_map { |name| problem(base, name) }

puts failures.empty? ? "OK" : failures
exit 1 unless failures.empty?
