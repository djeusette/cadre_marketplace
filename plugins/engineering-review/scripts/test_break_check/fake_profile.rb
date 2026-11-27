require "rbconfig"
require_relative "test_helper"
require_relative "../break_check/profile"

# The ExUnit profile, running fake_tests.rb in place of `mix test`.
module FakeProfile
  FAKE = File.expand_path("fake_tests.rb", __dir__)

  def self.fields(timeout: 10)
    RepoHelper::EXUNIT.except("env").merge("command" => [RbConfig.ruby, FAKE, "{files}"], "timeout" => timeout)
  end

  def self.call(timeout: 10) = BreakCheck::Profiles.build("fake", fields(timeout:), partition: nil)
end
