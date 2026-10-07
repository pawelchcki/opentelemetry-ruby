# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # MetricsReporter defines an interface used for reporting metrics from
        # span processors (like the BatchSpanProcessor) and exporters. It can
        # be used to report metrics such as dropped spans, and successful and
        # failed export attempts. This exists to decouple the Trace SDK from
        # the unstable OpenTelemetry Metrics API. An example implementation in
        # terms of StatsD is:
        #
        # @example
        #   module MetricsReporter
        #     def add_to_counter(metric, increment: 1, labels: {})
        #       StatsD.increment(metric, increment, labels, no_prefix: true)
        #     end
        #     def record_value(metric, value:, labels: {})
        #       StatsD.distribution(metric, value, labels, no_prefix: true)
        #     end
        #     def observe_value(metric, value:, labels: {})
        #       StatsD.gauge(metric, value, labels, no_prefix: true)
        #     end
        #   end
        module MetricsReporter
          extend self

          # Adds an increment to a metric with the provided labels.
          #
          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @param [String] metric The metric name.
          # @option options [Numeric] increment An optional increment to report.
          # @option options [Hash<String, String>] labels Optional labels to
          #   associate with the metric.
          def add_to_counter(metric, options = {})
            OpenTelemetry::Internal.validate_options(options, [:increment, :labels])
            _increment = options.fetch(:increment, 1)
            _labels = options.fetch(:labels) { {} }
            nil
          end

          # Records a value for a metric with the provided labels.
          #
          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @param [String] metric The metric name.
          # @option options [Numeric] value The value to report.
          # @option options [Hash<String, String>] labels Optional labels to
          #   associate with the metric.
          def record_value(metric, options = {})
            OpenTelemetry::Internal.validate_options(options, [:value, :labels], [:value])
            _value = options.fetch(:value)
            _labels = options.fetch(:labels) { {} }
            nil
          end

          # Observes a value for a metric with the provided labels.
          #
          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @param [String] metric The metric name.
          # @option options [Numeric] value The value to observe.
          # @option options [Hash<String, String>] labels Optional labels to
          #   associate with the metric.
          def observe_value(metric, options = {})
            OpenTelemetry::Internal.validate_options(options, [:value, :labels], [:value])
            _value = options.fetch(:value)
            _labels = options.fetch(:labels) { {} }
            nil
          end
        end
      end
    end
  end
end
