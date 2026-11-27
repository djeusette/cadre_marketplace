require "rbconfig"
require_relative "../break_check/profile"

# The ExUnit profile, running fake_tests.rb in place of `mix test`.
module FakeProfile
  FAKE = File.expand_path("fake_tests.rb", __dir__)

  def self.call(timeout: 10)
    BreakCheck::Profiles.exunit(partition: 1).with(command: ->(files) { [{}, RbConfig.ruby, FAKE, *files] }, timeout:)
  end
end
