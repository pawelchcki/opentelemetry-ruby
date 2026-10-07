# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {Tracer} is the SDK implementation of {OpenTelemetry::Trace::Tracer}.
      class Tracer < OpenTelemetry::Trace::Tracer
        # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
        # @api private
        #
        # Returns a new {Tracer} instance.
        #
        # @param [String] name Instrumentation scope name
        # @param [String] version Instrumentation scope version
        # @param [TracerProvider] tracer_provider TracerProvider that initialized the tracer
        # @option options [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Instrumentation scope attributes
        #
        # @return [Tracer]
        def initialize(name, version, tracer_provider, options = {})
          OpenTelemetry::Internal.validate_options(options, [:attributes])
          attributes = options.fetch(:attributes, nil)
          @instrumentation_scope = InstrumentationScope.new(name, version, attributes || {}.freeze)
          @tracer_provider = tracer_provider
        end

        def start_root_span(name, options = {})
          OpenTelemetry::Internal.validate_options(options, [:attributes, :links, :start_timestamp, :kind])
          attributes = options.fetch(:attributes, nil)
          links = options.fetch(:links, nil)
          start_timestamp = options.fetch(:start_timestamp, nil)
          kind = options.fetch(:kind, nil)
          start_span(name, with_parent: Context.empty, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind)
        end

        def start_span(name, options = {})
          OpenTelemetry::Internal.validate_options(options, [:with_parent, :attributes, :links, :start_timestamp, :kind])
          with_parent = options.fetch(:with_parent, nil)
          attributes = options.fetch(:attributes, nil)
          links = options.fetch(:links, nil)
          start_timestamp = options.fetch(:start_timestamp, nil)
          kind = options.fetch(:kind, nil)
          with_parent ||= Context.current
          name ||= 'empty'
          kind ||= :internal

          @tracer_provider.internal_start_span(name, kind, attributes, links, start_timestamp, with_parent, @instrumentation_scope)
        end
      end
    end
  end
end
