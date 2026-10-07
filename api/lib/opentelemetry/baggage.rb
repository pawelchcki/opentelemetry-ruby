# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/baggage/propagation'
require 'opentelemetry/baggage/builder'
require 'opentelemetry/baggage/entry'

module OpenTelemetry
  # The Baggage module provides functionality to record and propagate
  # baggage in a distributed trace
  module Baggage
    extend self

    BAGGAGE_KEY = OpenTelemetry::Baggage::Propagation::ContextKeys.baggage_key
    EMPTY_BAGGAGE = {}.freeze
    private_constant(:BAGGAGE_KEY, :EMPTY_BAGGAGE)

    # Used to chain modifications to baggage. The result is a
    # context with an updated baggage. If only a single
    # modification is being made to baggage, use the other
    # methods on +Baggage+, if multiple modifications are being made, use
    # this one.
    #
    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @option options [Context] context The context to update with with new
    #   modified baggage. Defaults to +Context.current+
    # @return [Context]
    def build(options = {})
      OpenTelemetry::Internal.validate_options(options, [:context])
      context = options.fetch(:context) { Context.current }
      builder = Builder.new(baggage_for(context).dup)
      yield builder
      context.set_value(BAGGAGE_KEY, builder.entries)
    end

    # Returns a new context with empty baggage
    #
    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @option options [Context] context Context to clear baggage from. Defaults
    #   to +Context.current+
    # @return [Context]
    def clear(options = {})
      OpenTelemetry::Internal.validate_options(options, [:context])
      context = options.fetch(:context) { Context.current }
      context.set_value(BAGGAGE_KEY, EMPTY_BAGGAGE)
    end

    # Returns the corresponding baggage.entry (or nil) for key
    #
    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @param [String] key The lookup key
    # @option options [Context] context The context from which to retrieve
    #   the key.
    #   Defaults to +Context.current+
    # @return [String]
    def value(key, options = {})
      OpenTelemetry::Internal.validate_options(options, [:context])
      context = options.fetch(:context) { Context.current }
      entry = baggage_for(context)[key]
      entry && entry.value
    end

    # Returns the baggage
    #
    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @option options [Context] context The context from which to retrieve
    #   the baggage.
    #   Defaults to +Context.current+
    # @return [Hash]
    def values(options = {})
      OpenTelemetry::Internal.validate_options(options, [:context])
      context = options.fetch(:context) { Context.current }
      baggage_for(context).each_with_object({}) { |(key, entry), values| values[key] = entry.value }
    end

    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @api private
    def raw_entries(options = {})
      OpenTelemetry::Internal.validate_options(options, [:context])
      context = options.fetch(:context) { Context.current }
      baggage_for(context).dup.freeze
    end

    # Returns a new context with new key-value pair
    #
    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @param [String] key The key to store this value under
    # @param [String] value String value to be stored under key
    # @option options [String] metadata This is here to store properties
    #   received from other W3C Baggage implementations but is not exposed in
    #   OpenTelemetry. This is condsidered private API and not for use by
    #   end-users.
    # @option options [Context] context The context to update with new
    #   value. Defaults to +Context.current+
    # @return [Context]
    def set_value(key, value, options = {})
      OpenTelemetry::Internal.validate_options(options, [:metadata, :context])
      metadata = options.fetch(:metadata, nil)
      context = options.fetch(:context) { Context.current }
      new_baggage = baggage_for(context).dup
      new_baggage[key] = Entry.new(value, metadata)
      context.set_value(BAGGAGE_KEY, new_baggage)
    end

    # Returns a new context with value at key removed
    #
    # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
    # @param [String] key The key to remove
    # @option options [Context] context The context to remove baggage
    #   from. Defaults to +Context.current+
    # @return [Context]
    def remove_value(key, options = {})
      OpenTelemetry::Internal.validate_options(options, [:context])
      context = options.fetch(:context) { Context.current }
      baggage = baggage_for(context)
      return context unless baggage.key?(key)

      new_baggage = baggage.dup
      new_baggage.delete(key)
      context.set_value(BAGGAGE_KEY, new_baggage)
    end

    private

    def baggage_for(context)
      context.value(BAGGAGE_KEY) || EMPTY_BAGGAGE
    end
  end
end
