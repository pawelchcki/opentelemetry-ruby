# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'
require 'fiber'
require 'opentelemetry/internal/options'

require 'opentelemetry/error'
require 'opentelemetry/context'
require 'opentelemetry/baggage'
require 'opentelemetry/trace'
require 'opentelemetry/internal'
require 'opentelemetry/version'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
module OpenTelemetry
  extend self

  @mutex = Mutex.new
  @tracer_provider = Internal::ProxyTracerProvider.new

  attr_writer :propagation, :logger

  # @return [Object, Logger] configured Logger or a default STDOUT Logger.
  def logger
    @logger ||= begin
      logger = Logger.new($stdout)
      logger.level = Internal.log_level(ENV['OTEL_LOG_LEVEL'] || Logger::INFO)
      logger
    end
  end

  # Configures error handler used by {handle_error}.
  #
  # Assigned object must respond to +#call+ and accept the keyword arguments
  # +exception:+ and +message:+.
  #
  # @param [#call] error_handler The error handler to use
  #
  # @example Log OpenTelemetry errors with a custom prefix
  #   OpenTelemetry.error_handler = lambda do |exception: nil, message: nil|
  #     OpenTelemetry.logger.warn("otel: #{[message, exception&.message].compact.join(' - ')}")
  #   end
  def error_handler=(error_handler)
    @error_handler = error_handler
  end

  # @return [Callable] configured error handler or a default that logs the
  #   exception and message at ERROR level.
  def error_handler
    @error_handler ||= lambda do |options = {}|
      Internal.validate_options(options, [:exception, :message])
      exception = options[:exception]
      message = options[:message]
      details = [message, exception && exception.message, exception && exception.backtrace && exception.backtrace.first]
      logger.error("OpenTelemetry error: #{details.compact.join(' - ')}")
    end
  end

  # Handles an error by calling the configured error_handler.
  #
  # @param [Hash] options Keyword-style options, also accepted as a Hash on legacy Ruby.
  # @option options [Exception] exception The exception to be handled
  # @option options [String] message An error message.
  def handle_error(options = {})
    OpenTelemetry::Internal.validate_options(options, [:exception, :message])
    exception = options.fetch(:exception, nil)
    message = options.fetch(:message, nil)
    error_handler.call(exception: exception, message: message)
  end

  # Register the global tracer provider.
  #
  # @param [TracerProvider] provider A tracer provider to register as the
  #   global instance.
  def tracer_provider=(provider)
    @mutex.synchronize do
      if @tracer_provider.instance_of? Internal::ProxyTracerProvider
        logger.debug("Upgrading default proxy tracer provider to #{provider.class}")
        @tracer_provider.delegate = provider
      end
      @tracer_provider = provider
    end
  end

  # @return [Object, Trace::TracerProvider] registered tracer provider or a
  #   default no-op implementation of the tracer provider.
  def tracer_provider
    @mutex.synchronize { @tracer_provider }
  end

  # @return [Context::Propagation::Propagator] a propagator instance
  def propagation
    @propagation ||= Context::Propagation::NoopTextMapPropagator.new
  end
end
