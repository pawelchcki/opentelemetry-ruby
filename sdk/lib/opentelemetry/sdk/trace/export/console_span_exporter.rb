# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # Outputs {SpanData} to the console.
        #
        # Potentially useful for exploratory purposes.
        class ConsoleSpanExporter
          def initialize
            @stopped = false
          end

          def export(spans, options = {})
            OpenTelemetry::Internal.validate_options(options, [:timeout])
            _timeout = options.fetch(:timeout, nil)
            return FAILURE if @stopped

            Array(spans).each { |s| pp s }

            SUCCESS
          end

          def force_flush(options = {})
            OpenTelemetry::Internal.validate_options(options, [:timeout])
            _timeout = options.fetch(:timeout, nil)
            SUCCESS
          end

          def shutdown(options = {})
            OpenTelemetry::Internal.validate_options(options, [:timeout])
            _timeout = options.fetch(:timeout, nil)
            @stopped = true
            SUCCESS
          end
        end
      end
    end
  end
end
