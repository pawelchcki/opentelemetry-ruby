# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # Compatibility helpers shared by the API and SDK.
  module Internal
    # @api private
    def self.log_level(value)
      return value if value.is_a?(Integer)

      name = value.to_s.upcase
      raise ArgumentError, "invalid log level: #{value}" unless %w[DEBUG INFO WARN ERROR FATAL UNKNOWN].include?(name)

      Logger.const_get(name)
    end

    # @api private
    # Keeps option-hash calls equivalent to keyword calls on older interpreters.
    def self.validate_options(options, allowed, required = [])
      raise ArgumentError, 'options must be a Hash' unless options.is_a?(Hash)

      missing = required.reject { |key| options.key?(key) }
      raise_option_error('missing', missing) unless missing.empty?

      unknown = options.keys - allowed
      raise_option_error('unknown', unknown) unless unknown.empty?
    end

    # @api private
    def self.raise_option_error(kind, keys)
      noun = keys.size == 1 ? 'keyword' : 'keywords'
      raise ArgumentError, "#{kind} #{noun}: #{keys.map(&:inspect).join(', ')}"
    end
    private_class_method :raise_option_error
  end
end
