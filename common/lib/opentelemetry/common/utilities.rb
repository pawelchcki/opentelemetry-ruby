# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'
require 'opentelemetry/common/clock'

module OpenTelemetry
  module Common
    # Utilities contains common helpers.
    module Utilities
      extend self

      UNTRACED_KEY = Context.create_key('untraced')
      private_constant :UNTRACED_KEY

      STRING_PLACEHOLDER = ''.encode(::Encoding::UTF_8).freeze

      # Returns nil if timeout is nil, 0 if timeout has expired,
      # or the remaining (positive) time left in seconds.
      #
      # @param [Numeric] timeout The timeout in seconds. May be nil.
      # @param [Numeric] start_time Start time for timeout returned
      #   by {timeout_timestamp}.
      #
      # @return [Numeric] remaining (positive) time left in seconds.
      #   May be nil.
      def maybe_timeout(timeout, start_time)
        return nil if timeout.nil?

        timeout -= (timeout_timestamp - start_time)
        return 0 unless timeout > 0

        timeout
      end

      # Returns a timestamp suitable to pass as the start_time
      # argument to {maybe_timeout}. This has no meaning outside
      # of the current process.
      #
      # @return [Numeric]
      def timeout_timestamp
        Clock.monotonic_nanoseconds / 1_000_000_000.0
      end

      # Converts the provided timestamp to nanosecond integer
      #
      # @param timestamp [Time] the timestamp to convert, defaults to Time.now
      # @return [Integer]
      def time_in_nanoseconds(timestamp = Time.now)
        (timestamp.to_r * 1_000_000_000).to_i
      end

      # Encodes a string in utf8
      #
      # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
      # @param [String] string The string to be utf8 encoded
      # @option options [boolean] binary This option is for displaying binary data
      # @option options [String, nil] placeholder The fallback value to be used if encoding fails
      #
      # @return [String, nil]
      def utf8_encode(string, options = {})
        OpenTelemetry::Internal.validate_options(options, [:binary, :placeholder])
        binary = options.fetch(:binary, false)
        placeholder = options.fetch(:placeholder) { STRING_PLACEHOLDER }
        string = string.to_s

        if binary
          # This option is useful for "gracefully" displaying binary data that
          # often contains text such as marshalled objects
          string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        elsif string.encoding == ::Encoding::UTF_8
          string
        elsif string.encoding == ::Encoding::ASCII_8BIT
          utf8_string = string.dup.force_encoding(::Encoding::UTF_8)
          raise Encoding::InvalidByteSequenceError, 'binary string is not valid UTF-8' unless utf8_string.valid_encoding?

          utf8_string
        else
          string.encode(::Encoding::UTF_8)
        end
      rescue StandardError => e
        OpenTelemetry.logger.debug("Error encoding string in UTF-8: #{e}")

        placeholder
      end

      # Formats exception details as UTF-8 on both legacy and modern Ruby.
      #
      # @param [Exception] exception
      # @return [String]
      def exception_stacktrace(exception)
        stacktrace = if exception.respond_to?(:full_message)
                       exception.full_message(highlight: false, order: :top)
                     else
                       ["#{exception.class}: #{exception.message}", *Array(exception.backtrace)].join("\n")
                     end
        stacktrace.encode('UTF-8', invalid: :replace, undef: :replace, replace: "\uFFFD")
      end

      # Truncates a string if it exceeds the size provided.
      #
      # @param [String] string The string to be truncated
      # @param [Integer] size The max size of the string
      #
      # @return [String]
      def truncate(string, size)
        string.size > size ? "#{string[0...(size - 3)]}..." : string
      end

      def truncate_attribute_value(value, limit)
        case value
        when Array
          value.map { |x| truncate_attribute_value(x, limit) }
        when String
          truncate(value, limit)
        else
          value
        end
      end

      # Disables tracing within the provided block
      # If no block is provided instead returns an
      # untraced ctx.
      #
      # @param [optional Context] context Accepts an explicit context, defaults to current
      def untraced(context = Context.current)
        context = context.set_value(UNTRACED_KEY, true)
        if block_given?
          Context.with_current(context) { |ctx| yield ctx } # rubocop:disable Style/ExplicitBlockArgument
        else
          context
        end
      end

      # Detects whether the current context has been set to disable tracing.
      def untraced?(context = nil)
        context ||= Context.current
        !!context.value(UNTRACED_KEY)
      end

      # Returns a URL string with userinfo removed.
      #
      # @param [String] url The URL string to cleanse.
      #
      # @return [String] the cleansed URL.
      def cleanse_url(url)
        cleansed_url = URI.parse(url)
        cleansed_url.password = nil
        cleansed_url.user = nil
        cleansed_url.to_s
      rescue URI::Error
        url
      end

      # Returns the first non nil environment variable requested,
      # or the default value if provided.
      #
      # @param [String] env_vars The environment variable(s) to retrieve
      # @note A final options Hash may contain :default, the fallback value
      #   when none of the requested environment variables are present.
      #
      # @return [String]
      def config_opt(*env_vars)
        options = env_vars.last.is_a?(Hash) ? env_vars.pop : {}
        OpenTelemetry::Internal.validate_options(options, [:default])
        default = options.fetch(:default, nil)
        ENV.values_at(*env_vars).compact.fetch(0, default)
      end

      # Returns a true if the provided url is valid
      #
      # @param [String] url the URL string to test validity
      #
      # @return [boolean]
      def valid_url?(url)
        return false if url.nil? || url.strip.empty?

        URI(url)
        true
      rescue URI::InvalidURIError
        false
      end

      # Returns true if exporter is a valid exporter.
      def valid_exporter?(exporter)
        exporter && [:export, :shutdown, :force_flush].all? { |m| exporter.respond_to?(m) }
      end
    end
  end
end

require_relative 'http/client_context'
