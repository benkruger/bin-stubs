# frozen_string_literal: true

return if defined?(WarningFilter)

module WarningFilter
  APP = ENV.fetch('APP_DIR', Dir.pwd)
  ROOTS = [File.expand_path(APP), File.realpath(APP)].uniq.freeze

  def self.from_repo?(message)
    ROOTS.any? do |root|
      message.start_with?("#{root}/") && !message.start_with?("#{root}/vendor/")
    end
  end

  def warn(message, **)
    raise "Ruby warning (no-warnings gate):\n#{message}" if WarningFilter.from_repo?(message)

    nil
  end
end

Warning.extend(WarningFilter)
