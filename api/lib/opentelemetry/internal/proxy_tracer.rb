# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyTracer} is an implementation of {OpenTelemetry::Trace::Tracer}. It is returned from
    # the ProxyTracerProvider until a delegate tracer provider is installed. After the delegate
    # tracer provider is installed, the ProxyTracer will delegate to the corresponding "real"
    # tracer.
    class ProxyTracer < Trace::Tracer
      attr_writer :delegate

      # Returns a new {ProxyTracer} instance.
      #
      # @return [ProxyTracer]
      def initialize
        @delegate = nil
      end

      def start_root_span(name, options = {})
        OpenTelemetry::Internal.validate_options(options, [:attributes, :links, :start_timestamp, :kind])
        attributes = options.fetch(:attributes, nil)
        links = options.fetch(:links, nil)
        start_timestamp = options.fetch(:start_timestamp, nil)
        kind = options.fetch(:kind, nil)
        return @delegate.start_root_span(name, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind) unless @delegate.nil?

        super
      end

      def start_span(name, options = {})
        OpenTelemetry::Internal.validate_options(options, [:with_parent, :attributes, :links, :start_timestamp, :kind])
        with_parent = options.fetch(:with_parent, nil)
        attributes = options.fetch(:attributes, nil)
        links = options.fetch(:links, nil)
        start_timestamp = options.fetch(:start_timestamp, nil)
        kind = options.fetch(:kind, nil)
        return @delegate.start_span(name, with_parent: with_parent, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind) unless @delegate.nil?

        super
      end
    end
  end
end
