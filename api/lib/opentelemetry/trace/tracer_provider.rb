# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of a tracer provider.
    class TracerProvider
      # Returns a {Tracer} instance.
      #
      # Supports both positional arguments (legacy) and keyword arguments:
      #   tracer('name', '1.0')                                    # legacy positional
      #   tracer(name: 'name', version: '1.0', attributes: {...})  # keyword
      #
      # When both positional and keyword arguments are provided for the same
      # parameter, the keyword argument takes precedence.
      #
      # @option options [String] name Instrumentation scope name
      # @option options [String] version Instrumentation scope version
      # @option options [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
      #   Instrumentation scope attributes
      #
      # @return [Tracer]
      # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
      def tracer(deprecated_name = nil, deprecated_version = nil, options = {})
        if deprecated_version.is_a?(Hash)
          options = deprecated_version
        elsif deprecated_name.is_a?(Hash)
          options = deprecated_name
        end
        OpenTelemetry::Internal.validate_options(options, [:name, :version, :attributes])
        _name = options.fetch(:name, nil)
        _version = options.fetch(:version, nil)
        _attributes = options.fetch(:attributes, nil)
        @tracer ||= Tracer.new
      end
    end
  end
end
