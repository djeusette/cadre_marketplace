#!/usr/bin/env ruby
# Prints, as JSON, a repo's Skills table and what each of its rows lacks.
#
#   ruby skills_table.rb <repo root>
#
# The table is the first block of `|` lines under `## Skills` in the repo's
# AGENTS.md, up to the next `## ` heading, starting with the header
# `| Skill | When | Install |`. A committed skill lives in
# .agents/skills/<name>/SKILL.md and has the link
# .claude/skills/<name> -> ../../.agents/skills/<name>. Any other row names a
# plugin skill and says how to install it.
#
#   {"table": true, "imports_agents_md": true,
#    "rows": [{"skill", "when", "install", "committed", "problems": [...]}],
#    "unlisted": [folders of .agents/skills that no committed row names]}

require "json"

USAGE = "Usage: ruby skills_table.rb <repo root>".freeze
HEADER = %w[Skill When Install].freeze
COMMITTED = "committed in .agents/skills/".freeze
PLUGIN_INSTALL = /\Aclaude plugin install [\w.-]+@[\w.-]+\z/

SEPARATOR = /\A\|(\s*:?-+:?\s*\|)+\z/

# Files are read as UTF-8 whatever the locale: an agent's shell may have none.
def read_utf8(path) = File.read(path, encoding: "UTF-8")

# Lines outside fenced code blocks, so an example table in one isn't the table.
def outside_fences(lines)
  fenced = false
  lines.reject do |line|
    fence = line.start_with?("```")
    fenced = !fenced if fence
    fence || fenced
  end
end

def table_lines(agents_md)
  return [] unless File.file?(agents_md)

  lines = outside_fences(read_utf8(agents_md).lines.map(&:rstrip))
  heading = lines.index("## Skills") or return []
  section = lines.drop(heading + 1).take_while { |line| !line.start_with?("## ") }
  section.drop_while { |line| !line.start_with?("|") }.take_while { |line| line.start_with?("|") }
end

def cells(line)
  line.strip.delete_prefix("|").delete_suffix("|").split(/(?<!\\)\|/).map { |cell| cell.gsub("\\|", "|").delete("`").strip }
end

def committed_problems(root, name)
  folder = File.join(root, ".agents", "skills", name)
  link = File.join(root, ".claude", "skills", name)
  target = "../../.agents/skills/#{name}"
  problems = []
  if !File.directory?(folder)
    problems << "no folder .agents/skills/#{name}"
  elsif !File.file?(File.join(folder, "SKILL.md"))
    problems << "no SKILL.md in .agents/skills/#{name}"
  end
  linked = File.symlink?(link) && File.readlink(link) == target
  problems << ".claude/skills/#{name} does not link to #{target}" unless linked
  problems
end

def row(root, skill, when_, install)
  committed = install == COMMITTED
  problems =
    if committed then committed_problems(root, skill)
    elsif install.match?(PLUGIN_INSTALL) then []
    else ["Install is neither committed in .agents/skills/ nor claude plugin install <plugin>@<marketplace>"]
    end
  { "skill" => skill, "when" => when_, "install" => install, "committed" => committed, "problems" => problems }
end

def folders(root)
  dir = File.join(root, ".agents", "skills")
  return [] unless File.directory?(dir)

  Dir.children(dir).reject { |name| name.start_with?(".") }.select { |name| File.directory?(File.join(dir, name)) }.sort
end

def imports_agents_md?(root)
  claude_md = File.join(root, "CLAUDE.md")
  File.file?(claude_md) && read_utf8(claude_md).lines.any? { |line| line.chomp == "@AGENTS.md" }
end

def report(root)
  lines = table_lines(File.join(root, "AGENTS.md"))
  table = lines.length >= 2 && cells(lines.first) == HEADER && lines[1].delete(" ").match?(SEPARATOR)
  rows = table ? lines.drop(2).map { |line| row(root, *cells(line).values_at(0, 1, 2).map(&:to_s)) } : []
  listed = rows.select { |entry| entry["committed"] }.map { |entry| entry["skill"] }
  { "table" => table, "imports_agents_md" => imports_agents_md?(root), "rows" => rows, "unlisted" => folders(root) - listed }
end

unless ARGV.length == 1 && File.directory?(ARGV.first)
  warn USAGE
  exit 1
end

puts JSON.generate(report(File.expand_path(ARGV.first)))
