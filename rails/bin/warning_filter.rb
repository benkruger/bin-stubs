# frozen_string_literal: true

# Warnings from this app fail the test run. Warnings from gems stay quiet.
return if defined?(WarningFilter)

module WarningFilter
  REPO_ROOT = File.expand_path('..', __dir__).freeze
  VENDOR = "#{REPO_ROOT}/vendor/".freeze

  def self.from_repo?(message)
    message.start_with?(REPO_ROOT) && !message.start_with?(VENDOR)
  end
end

warn_verbose = $VERBOSE
$VERBOSE = nil
module Warning
  def warn(message, **)
    raise "Ruby warning (no-warnings gate):\n#{message}" if WarningFilter.from_repo?(message)

    nil
  end
end
$VERBOSE = warn_verbose
