# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Propagation
      module TraceContext
        # Propagates trace context using the W3C Trace Context format
        class TextMapPropagator
          TRACEPARENT_KEY = 'traceparent'
          TRACESTATE_KEY = 'tracestate'
          FIELDS = [TRACEPARENT_KEY, TRACESTATE_KEY].freeze

          private_constant :TRACEPARENT_KEY, :TRACESTATE_KEY, :FIELDS

          # Inject trace context into the supplied carrier.
          #
          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @param [Carrier] carrier The mutable carrier to inject trace context into
          # @option options [Context] context The context to read trace context from
          # @option options [Setter] setter If the optional setter is provided, it
          #   will be used to write context into the carrier, otherwise the default
          #   text map setter will be used.
          def inject(carrier, options = {})
            OpenTelemetry::Internal.validate_options(options, [:context, :setter])
            context = options.fetch(:context) { Context.current }
            setter = options.fetch(:setter) { Context::Propagation.text_map_setter }
            span_context = Trace.current_span(context).context
            return unless span_context.valid?

            setter.set(carrier, TRACEPARENT_KEY, TraceParent.from_span_context(span_context).to_s)
            setter.set(carrier, TRACESTATE_KEY, span_context.tracestate.to_s) unless span_context.tracestate.empty?
            nil
          end

          # Extract trace context from the supplied carrier.
          # If extraction fails, the original context will be returned
          #
          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @param [Carrier] carrier The carrier to get the header from
          # @option options [Context] context Context to be updated with the trace context
          #   extracted from the carrier. Defaults to +Context.current+.
          # @option options [Getter] getter If the optional getter is provided, it
          #   will be used to read the header from the carrier, otherwise the default
          #   text map getter will be used.
          #
          # @return [Context] context updated with extracted baggage, or the original context
          #   if extraction fails
          def extract(carrier, options = {})
            OpenTelemetry::Internal.validate_options(options, [:context, :getter])
            context = options.fetch(:context) { Context.current }
            getter = options.fetch(:getter) { Context::Propagation.text_map_getter }
            trace_parent_value = getter.get(carrier, TRACEPARENT_KEY)
            return context unless trace_parent_value

            tp = TraceParent.from_string(trace_parent_value)
            tracestate = Tracestate.from_string(getter.get(carrier, TRACESTATE_KEY))

            span_context = Trace::SpanContext.new(trace_id: tp.trace_id,
                                                  span_id: tp.span_id,
                                                  trace_flags: tp.flags,
                                                  tracestate: tracestate,
                                                  remote: true)
            span = OpenTelemetry::Trace.non_recording_span(span_context)
            OpenTelemetry::Trace.context_with_span(span, parent_context: context)
          rescue OpenTelemetry::Error
            context
          end

          # Returns the predefined propagation fields. If your carrier is reused, you
          # should delete the fields returned by this method before calling +inject+.
          #
          # @return [Array<String>] a list of fields that will be used by this propagator.
          def fields
            FIELDS
          end
        end
      end
    end
  end
end
