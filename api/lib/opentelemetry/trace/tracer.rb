# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of Tracer.
    class Tracer
      # This is a helper for the default use-case of extending the current trace with a span.
      #
      # With this helper:
      #
      #   OpenTelemetry.tracer.in_span('do-the-thing') do ... end
      #
      # Equivalent without helper:
      #
      #   OpenTelemetry::Trace.with_span(tracer.start_span('do-the-thing')) do ... end
      #
      # On exit, the Span that was active before calling this method will be reactivated. If an
      # exception occurs during the execution of the provided block, it will be recorded on the
      # span and reraised.
      #
      # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
      # @param name [String] the name of the span
      # @option options attributes [optional Hash] attributes to attach to the span {String => String,
      # Numeric, Boolean, Array<String, Numeric, Boolean>}
      # @option options links [optional Array] an array of OpenTelemetry::Trace::Link instances
      # @option options start_timestamp [optional Time] timestamp to use as the start time of the span
      # @option options kind [optional Symbol] One of :internal, :server, :client, :producer, :consumer
      #
      # @yield [span, context] yields the newly created span and a context containing the
      #   span to the block.
      def in_span(name, options = {})
        OpenTelemetry::Internal.validate_options(options, [:attributes, :links, :start_timestamp, :kind, :record_exception])
        attributes = options.fetch(:attributes, nil)
        links = options.fetch(:links, nil)
        start_timestamp = options.fetch(:start_timestamp, nil)
        kind = options.fetch(:kind, nil)
        record_exception = options.fetch(:record_exception, true)
        span = nil
        span = start_span(name, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind)
        Trace.with_span(span) { |s, c| yield s, c } # rubocop:disable Style/ExplicitBlockArgument
      rescue Exception => e # rubocop:disable Lint/RescueException
        span.record_exception(e) if span && record_exception
        span.status = Status.error("Unhandled exception of type: #{e.class}") if span
        raise e
      ensure
        span.finish if span
      end

      def start_root_span(name, options = {})
        OpenTelemetry::Internal.validate_options(options, [:attributes, :links, :start_timestamp, :kind])
        _attributes = options.fetch(:attributes, nil)
        _links = options.fetch(:links, nil)
        _start_timestamp = options.fetch(:start_timestamp, nil)
        _kind = options.fetch(:kind, nil)
        Span::INVALID
      end

      # Used when a caller wants to manage the activation/deactivation and lifecycle of
      # the Span and its parent manually.
      #
      # Parent context can be either passed explicitly, or inferred from currently activated span.
      #
      # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
      # @option options [Context] with_parent Explicitly managed parent context
      #
      # @return [Span]
      def start_span(name, options = {})
        OpenTelemetry::Internal.validate_options(options, [:with_parent, :attributes, :links, :start_timestamp, :kind])
        with_parent = options.fetch(:with_parent, nil)
        _attributes = options.fetch(:attributes, nil)
        _links = options.fetch(:links, nil)
        _start_timestamp = options.fetch(:start_timestamp, nil)
        _kind = options.fetch(:kind, nil)
        span = OpenTelemetry::Trace.current_span(with_parent)

        if span.recording?
          OpenTelemetry::Trace.non_recording_span(span.context)
        else
          # Either the span is valid and non-recording, in which case we return it,
          # or there was no span in the Context and Trace.current_span returned Span::INVALID,
          # which is what we're supposed to return.
          span
        end
      end
    end
  end
end
