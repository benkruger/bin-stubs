# frozen_string_literal: true

return if defined?(WarningFilter)

# Raises on any Ruby warning from this app's own code. Warnings from gems and
# vendor/ stay quiet. bin/test loads it through RUBYOPT.
module WarningFilter
  UP = File.basename(__dir__) == '_root' ? '../..' : '..'
  ROOTS = [__dir__, File.dirname(File.expand_path(__FILE__))].uniq.map do |dir|
    File.expand_path(UP, dir)
  end.freeze

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
