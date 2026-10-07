# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # Operational implementation of Baggage::Builder
    class Builder
      # @api private
      attr_reader :entries

      # @api private
      def initialize(entries)
        @entries = entries
      end

      # Set key-value in the to-be-created baggage
      #
      # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
      # @param [String] key The key to store this value under
      # @param [String] value String value to be stored under key
      # @option options [String] metadata This is here to store properties
      #   received from other W3C Baggage implementations but is not exposed in
      #   OpenTelemetry. This is condsidered private API and not for use by
      #   end-users.
      def set_value(key, value, options = {})
        OpenTelemetry::Internal.validate_options(options, [:metadata])
        metadata = options.fetch(:metadata, nil)
        @entries[key] = OpenTelemetry::Baggage::Entry.new(value, metadata)
      end

      # Removes key from the to-be-created baggage
      #
      # @param [String] key The key to remove
      def remove_value(key)
        @entries.delete(key)
      end

      # Clears all baggage from the to-be-created baggage
      def clear
        @entries.clear
      end
    end
  end
end
