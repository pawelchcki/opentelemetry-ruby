# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api private
        #
        # Implements sampling based on a probability.
        class TraceIdRatioBased
          attr_reader :description

          def initialize(probability)
            @probability = probability
            @id_upper_bound = (probability * ((2**64) - 1)).ceil
            @description = format('TraceIdRatioBased{%.6f}', probability)
          end

          def ==(other)
            @description == other.description
          end

          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @api private
          #
          # See {Samplers}.
          def should_sample?(options = {})
            OpenTelemetry::Internal.validate_options(options, [:trace_id, :parent_context, :links, :name, :kind, :attributes], [:trace_id, :parent_context, :links, :name, :kind, :attributes])
            trace_id = options.fetch(:trace_id)
            parent_context = options.fetch(:parent_context)
            _links = options.fetch(:links)
            _name = options.fetch(:name)
            _kind = options.fetch(:kind)
            _attributes = options.fetch(:attributes)
            tracestate = OpenTelemetry::Trace.current_span(parent_context).context.tracestate
            if sample?(trace_id)
              Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate)
            else
              Result.new(decision: Decision::DROP, tracestate: tracestate)
            end
          end

          private

          def sample?(trace_id)
            # rubocop:disable-next Lint/FloatComparison
            @probability == 1.0 || trace_id[8, 8].unpack('Q>').first < @id_upper_bound
          end
        end
      end
    end
  end
end
