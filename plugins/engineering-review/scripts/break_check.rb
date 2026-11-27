#!/usr/bin/env ruby
# Breaks branches one at a time and records which test caught each one.
# See ../skills/break-check/contract.md.
require_relative "break_check/cli"

if $PROGRAM_NAME == __FILE__
  $stdout.sync = true
  exit BreakCheck::CLI.run(ARGV)
end
