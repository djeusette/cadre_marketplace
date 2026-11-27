# A stand-in for `mix test`, for the runner's tests. It reads `mode=<word>`
# from the repo's lib/*.ex files and acts on the first word that isn't
# `pass`, printing ExUnit-shaped output.
File.write(".invoked", "yes")

# A test that fails when run alone but passes beside another: order-dependent.
if ARGV == ["test/b_test.exs"] && File.read("lib/b.ex").include?("alone_fails")
  puts "  1) test b_test (BTest)"
  exit 1
end

mode = Dir["lib/*.ex"].sort.filter_map { File.read(_1)[/mode=(\w+)/, 1] }.find { _1 != "pass" } || "pass"

case mode
when "pass"
  puts "Finished in 0.1 seconds\n3 tests, 0 failures"
when "fail"
  puts "  1) test big (ATest)\n     test/a_test.exs:3\n\n3 tests, 1 failure"
  exit 1
when "child"
  puts "  1) test child #{File.exist?(".breaks/child") ? "tracked" : "missing"} (ATest)"
  exit 1
when "names_but_pass"
  puts "  1) test big (ATest)\n3 tests, 0 failures"
when "fail_utf8"
  puts "  1) test a → b (ATest)"
  exit 1
when "lock_file"
  File.chmod(0o444, "lib/a.ex")
  puts "  1) test big (ATest)"
  exit 1
when "compile"
  puts "== Compilation error in file lib/a.ex =="
  exit 1
when "infra_once"
  attempts = File.exist?(".attempts") ? File.read(".attempts").to_i : 0
  File.write(".attempts", (attempts + 1).to_s)
  puts(attempts.zero? ? "** (Postgrex.Error) FATAL 53300 (too_many_connections)" : "  1) test big (ATest)")
  exit 1
when "infra_and_fail"
  puts "** (Postgrex.Error) FATAL 53300 (too_many_connections)\n  1) test big (ATest)"
  exit 1
when "hang"
  File.write(".hang-pid", Process.pid.to_s)
  sleep 30
when "hang_exit_0"
  trap("TERM") { exit 0 }
  sleep 30
when "garbage"
  puts "something exploded"
  exit 1
when "refuse"
  puts "Another mix test run is using this partition"
  exit 1
when "count_ledger"
  lines = File.exist?(".breaks/ledger.jsonl") ? File.readlines(".breaks/ledger.jsonl").size : 0
  puts "  1) test ledger has #{lines} (ATest)"
  exit 1
end
