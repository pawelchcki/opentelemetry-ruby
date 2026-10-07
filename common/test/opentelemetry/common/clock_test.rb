# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::Clock do
  it 'reports wall time in integer nanoseconds' do
    before = OpenTelemetry::Common::Utilities.time_in_nanoseconds
    actual = OpenTelemetry::Common::Clock.realtime_nanoseconds
    after = OpenTelemetry::Common::Utilities.time_in_nanoseconds

    assert_kind_of Integer, actual
    assert_operator actual, :>=, before
    assert_operator actual, :<=, after
  end

  it 'reports elapsed time independently of wall time' do
    clock = OpenTelemetry::Common::Clock
    before = clock.monotonic_nanoseconds
    Time.stub(:now, Time.at(0)) do
      sleep 0.001
      assert_operator clock.monotonic_nanoseconds, :>, before
    end
  end
end
