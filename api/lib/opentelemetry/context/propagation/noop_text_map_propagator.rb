# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # @api private
      class NoopTextMapPropagator
        EMPTY_LIST = [].freeze
        private_constant(:EMPTY_LIST)

        def inject(carrier, options = {})
          OpenTelemetry::Internal.validate_options(options, [:context, :setter])
          _context = options.fetch(:context) { Context.current }
          _setter = options.fetch(:setter) { Context::Propagation.text_map_setter }
          nil
        end

        def extract(carrier, options = {})
          OpenTelemetry::Internal.validate_options(options, [:context, :getter])
          context = options.fetch(:context) { Context.current }
          _getter = options.fetch(:getter) { Context::Propagation.text_map_getter }
          context
        end

        def fields
          EMPTY_LIST
        end
      end
    end
  end
end
