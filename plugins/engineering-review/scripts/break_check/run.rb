require_relative "breaks"
require_relative "ledger"
require_relative "profile"
require_relative "workspace"

module BreakCheck
  class Refused < Error; end

  Outcome = Data.define(:brk, :result, :tests_failed, :reason)

  # One run of the test command: what it printed and how it ended.
  TestRun = Data.define(:output, :status, :timed_out) do
    def passed? = !timed_out && status.success?
  end

  # Runs breaks one at a time, each on a set of tests that ran green first,
  # exactly as the break runs them, and records a break as caught only when
  # the run fails and names a failing test.
  class Run
    LABELS = {caught: "caught", not_caught: "NOT CAUGHT", doesnt_compile: "doesn't compile", inconclusive: "inconclusive"}.freeze
    TAIL = 20

    def initialize(profile:, out: $stdout)
      @profile = profile
      @out = out
      @root = Dir.pwd
      @workspace = Workspace.new(@root, out:)
      @ledger = Ledger.new(@root)
    end

    def call(breaks)
      with_traps do
        @workspace.lock_and_recover do
          problems = Breaks.problems(breaks, root: @root) + @ledger.name_conflicts(breaks)
          raise Refused, problems.join("\n") if problems.any?

          proofs = breaks.to_h { [_1, @ledger.proof(_1)] }
          to_run = breaks.reject { proofs[_1] }
          to_run.map(&:tests).uniq.each { baseline(_1) }
          breaks.map { |brk| proofs[brk] ? proven(brk, proofs[brk]) : run_break(brk) }.tap { summary(_1) }
        end
      end
    end

    private

    def proven(brk, proof)
      @out.puts "proven  #{brk.name}  (fresh in the ledger)"
      Outcome.new(brk:, result: :caught, tests_failed: proof["tests_failed"], reason: nil)
    end

    def baseline(tests)
      run = execute(tests)
      return if run.passed?

      names = names(run.output)
      detail = names.any? ? names.join("\n") : tail(run.output)
      raise Refused, "the tests are not green before any break:\n#{detail}"
    end

    def run_break(brk)
      line = Breaks.occurrences(BreakCheck.read(File.join(@root, brk.file)), brk.from).first
      outcome = nil
      @workspace.swap(brk) do
        outcome = attempt(brk)
        outcome = attempt(brk) if outcome == :infrastructure
        outcome = Outcome.new(brk:, result: :inconclusive, tests_failed: [], reason: "infrastructure failed twice") if outcome == :infrastructure
      end
      @ledger.record(brk, line:, tests_failed: outcome.tests_failed, profile: @profile.name) if outcome.result == :caught
      print_outcome(outcome)
      outcome
    end

    def attempt(brk) = classify(brk, execute(brk.tests))

    def classify(brk, run)
      output = run.output
      return Outcome.new(brk:, result: :inconclusive, tests_failed: [], reason: "timed out after #{@profile.timeout}s") if run.timed_out
      return Outcome.new(brk:, result: :doesnt_compile, tests_failed: [], reason: nil) if output.match?(@profile.compile_error)
      return :infrastructure if @profile.infrastructure && output.match?(@profile.infrastructure)
      return Outcome.new(brk:, result: :inconclusive, tests_failed: [], reason: "another test run") if @profile.refusal && output.match?(@profile.refusal)

      names = names(output)
      return Outcome.new(brk:, result: :caught, tests_failed: names, reason: nil) if names.any? && !run.status.success?
      return Outcome.new(brk:, result: :not_caught, tests_failed: [], reason: nil) if run.status.success?

      Outcome.new(brk:, result: :inconclusive, tests_failed: [], reason: "failed with no test named: #{tail(output, 3).tr("\n", " ")}")
    end

    def names(output) = output.scan(@profile.failing_test).map(&:first).uniq

    def tail(output, lines = TAIL) = output.lines.last(lines).join

    # Runs the test command in its own process group, so a timeout or an
    # interrupt stops it and everything it started.
    def execute(tests)
      env, *argv = @profile.command.call(tests)
      reader, writer = IO.pipe(Encoding::UTF_8)
      @child = Process.spawn(env, *argv, out: writer, err: writer, pgroup: true, chdir: @root)
      writer.close
      @workspace.track_child(@child) do
        output = Thread.new { reader.read.scrub }
        timed_out = output.join(@profile.timeout).nil?
        kill_child if timed_out
        _, status = Process.wait2(@child)
        TestRun.new(output: output.value, status:, timed_out:)
      end
    ensure
      @child = nil
      reader&.close
    end

    def kill_child
      return unless @child

      signal_group("TERM")
      sleep 0.5
      signal_group("KILL")
    end

    # macOS answers EPERM, not ESRCH, once only the group's zombie leader is left.
    def signal_group(signal)
      Process.kill("-#{signal}", @child)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end

    def with_traps
      previous = %w[INT TERM].to_h do |signal|
        [signal, trap(signal) { kill_child; raise SignalException, signal }]
      end
      yield
    ensure
      previous&.each { |signal, handler| trap(signal, handler) }
    end

    def print_outcome(outcome)
      label = LABELS.fetch(outcome.result)
      detail =
        case outcome.result
        when :caught then "  ← #{outcome.tests_failed.join(", ")}"
        when :inconclusive then "  (#{outcome.reason})"
        else ""
        end
      @out.puts "#{label}  #{outcome.brk.name}#{detail}"
    end

    def summary(outcomes)
      counts = LABELS.keys.to_h { |result| [result, outcomes.count { _1.result == result }] }
      @out.puts "#{counts[:caught]} caught, #{counts[:not_caught]} not caught, " \
        "#{counts[:doesnt_compile]} doesn't compile, #{counts[:inconclusive]} inconclusive"
    end
  end
end
