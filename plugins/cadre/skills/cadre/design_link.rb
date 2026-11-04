#!/usr/bin/env ruby
# Prints the link that opens a Claude Design canvas on one page or board.
#
#   ruby design_link.rb <canvas_url> --page <page id>
#   ruby design_link.rb <canvas_url> --board <board file>
#
# A canvas reads where to open from the link's fragment, #page-<hash> or
# #artboard-<hash>. The hash is the canvas's own: a cyrb53 variant, cut to 12
# hex characters. The canvas doesn't document this, and a fragment it doesn't
# know opens its default view, so a link that stops matching still opens.

USAGE = "Usage: ruby design_link.rb <canvas_url> (--page <page id> | --board <board file>)".freeze
PREFIXES = { "--page" => "page", "--board" => "artboard" }.freeze
WORD = 0xffffffff

def multiply(left, right)
  (left * right) & WORD
end

def place_hash(name)
  high = 0xdeadbeef
  low = 0x41c6ce57

  name.dup.force_encoding("UTF-8").encode("UTF-16LE").unpack("v*").each do |unit|
    high = multiply(high ^ unit, 2654435761)
    low = multiply(low ^ unit, 1597334677)
  end

  high = multiply(high ^ (high >> 16), 2246822507) ^ multiply(low ^ (low >> 13), 3266489909)
  low = multiply(low ^ (low >> 16), 2246822507) ^ multiply(high ^ (high >> 13), 3266489909)

  (((low & 0x1fffff) << 32) + high).to_s(16).rjust(14, "0")[-12..-1]
end

canvas_url, flag, name = ARGV
prefix = PREFIXES[flag]

abort USAGE unless ARGV.size == 3 && prefix && canvas_url.start_with?("https://") && !name.empty?

puts "#{canvas_url.split('#').first}##{prefix}-#{place_hash(name)}"
