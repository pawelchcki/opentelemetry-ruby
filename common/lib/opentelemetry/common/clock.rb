# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    # @api private
    # Ruby 1.9 does not expose clock_gettime; use its standard-library FFI.
    module Clock
      unless Process.respond_to?(:clock_gettime)
        require 'dl/import'

        # Legacy Linux clock bindings.
        module Native
          extend DL::Importer

          dlload 'librt.so.1'
          extern 'int clock_gettime(int, void*)'
        end
        private_constant :Native
      end

      # Returns process-local monotonic time for measuring durations.
      #
      # @return [Integer] monotonic nanoseconds
      def self.monotonic_nanoseconds
        if Process.respond_to?(:clock_gettime)
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
        else
          buffer = [0, 0].pack('l!l!')
          raise SystemCallError, 'clock_gettime failed' unless Native.clock_gettime(1, buffer).zero?

          seconds, nanoseconds = buffer.unpack('l!l!')
          (seconds * 1_000_000_000) + nanoseconds
        end
      end

      # Returns wall time as nanoseconds since the Unix epoch.
      #
      # @return [Integer] epoch nanoseconds
      def self.realtime_nanoseconds
        if Process.respond_to?(:clock_gettime)
          Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
        else
          (Time.now.to_r * 1_000_000_000).to_i
        end
      end
    end
  end
end
