#!/usr/bin/env ruby
# Breaks branches one at a time and records which test caught each one.
# See ../skills/break-check/contract.md.
#
# This file parses on any Ruby, so an old one gets this message rather
# than a syntax error from the files it loads.
if (RUBY_VERSION.split(".").map(&:to_i) <=> [3, 2, 0]) < 0
  puts "break_check.rb needs Ruby 3.2 or later; this is Ruby #{RUBY_VERSION}"
  exit 2
end

require_relative "break_check/cli"

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true
  exit BreakCheck::CLI.run(ARGV)
end
