# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # A text map propagator that composes an extractor and injector into a
      # single interface exposing inject and extract methods.
      class TextMapPropagator
        # Returns a Propagator that delegates inject and extract to the provided
        # injector and extractor
        #
        # @param [#inject] injector
        # @param [#extract] extractor
        def initialize(injector, extractor)
          raise ArgumentError, 'injector and extractor must both be non-nil' if injector.nil? || extractor.nil?

          @injector = injector
          @extractor = extractor
        end

        # Injects the provided context into a carrier using the underlying
        # injector. Logs a warning if injection fails.
        #
        # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
        # @param [Object] carrier A mutable carrier to inject context into.
        # @option options [Context] context Context to be injected into carrier. Defaults
        #   to +Context.current+.
        # @option options [Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        def inject(carrier, options = {})
          OpenTelemetry::Internal.validate_options(options, [:context, :setter])
          context = options.fetch(:context) { Context.current }
          setter = options.fetch(:setter) { Context::Propagation.text_map_setter }
          @injector.inject(carrier, context, setter)
          nil
        rescue StandardError => e
          OpenTelemetry.logger.warn "Error in Propagator#inject #{e.message}"
          nil
        end

        # Extracts and returns context from a carrier. Returns the provided
        # context and logs a warning if an error if extraction fails.
        #
        # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
        # @param [Object] carrier The carrier to extract context from.
        # @option options [Context] context Context to be updated with the state
        #   extracted from the carrier. Defaults to +Context.current+.
        # @option options [Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        #
        # @return [Context] a new context updated with state extracted from the
        #   carrier
        def extract(carrier, options = {})
          OpenTelemetry::Internal.validate_options(options, [:context, :getter])
          context = options.fetch(:context) { Context.current }
          getter = options.fetch(:getter) { Context::Propagation.text_map_getter }
          @extractor.extract(carrier, context, getter)
        rescue StandardError => e
          OpenTelemetry.logger.warn "Error in Propagator#extract #{e.message}"
          context
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          @injector.fields
        end
      end
    end
  end
end
