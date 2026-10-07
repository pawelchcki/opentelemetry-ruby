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
        # Implements a sampler returning a result with a constant decision.
        class ConstantSampler
          attr_reader :description

          def initialize(options = {})
            OpenTelemetry::Internal.validate_options(options, [:decision, :description], [:decision, :description])
            decision = options.fetch(:decision)
            description = options.fetch(:description)
            @decision = decision
            @description = description
          end

          def ==(other)
            @decision == other.decision && @description == other.description
          end

          # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
          # @api private
          #
          # See {Samplers}.
          def should_sample?(options = {})
            OpenTelemetry::Internal.validate_options(options, [:trace_id, :parent_context, :links, :name, :kind, :attributes], [:trace_id, :parent_context, :links, :name, :kind, :attributes])
            _trace_id = options.fetch(:trace_id)
            parent_context = options.fetch(:parent_context)
            _links = options.fetch(:links)
            _name = options.fetch(:name)
            _kind = options.fetch(:kind)
            _attributes = options.fetch(:attributes)
            Result.new(decision: @decision, tracestate: OpenTelemetry::Trace.current_span(parent_context).context.tracestate)
          end

          protected

          attr_reader :decision
        end
      end
    end
  end
end
