# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

root = File.expand_path('../..', File.dirname(__FILE__))
%w[api common registry sdk semantic_conventions].each do |component|
  $LOAD_PATH.unshift(File.join(root, component, 'lib'))
end

require 'minitest'
require 'minitest/test'
# Prevent unrelated globally installed Minitest plugins from changing this suite.
Minitest.extensions << 'legacy_runtime'
Minitest.autorun
require 'opentelemetry-sdk'

class LegacyRuntimeTest < Minitest::Test
  def setup
    @export = OpenTelemetry::SDK::Trace::Export
    @exporter = @export::InMemorySpanExporter.new
    @provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    @provider.add_span_processor(@export::SimpleSpanProcessor.new(@exporter))
    @tracer = @provider.tracer('legacy', '1.0', attributes: { 'scope.key' => 'value' })
  end

  def teardown
    @provider.shutdown
    OpenTelemetry::Context.clear
  end

  def test_parent_child_spans_and_scope_attributes
    @tracer.in_span('parent') do |parent|
      @tracer.in_span('child') do |child|
        assert_equal parent.context.trace_id, child.context.trace_id
        refute_equal parent.context.span_id, child.context.span_id
      end
    end
    child, parent = @exporter.finished_spans
    assert_equal parent.span_id, child.parent_span_id
    assert_equal 'value', child.instrumentation_scope.attributes['scope.key']
    assert_operator child.end_timestamp, :>=, child.start_timestamp
  end

  def test_keyword_style_tracer_call_remains_compatible
    tracer = @provider.tracer(name: 'keywords', version: '2.0', attributes: { 'key' => 'value' })
    tracer.in_span('span') {}
    scope = @exporter.finished_spans.first.instrumentation_scope
    assert_equal 'keywords', scope.name
    assert_equal '2.0', scope.version
    assert_equal 'value', scope.attributes['key']
  end

  def test_incoming_w3c_context_and_outgoing_propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    context = propagator.extract('traceparent' => '00-0123456789abcdef0123456789abcdef-0123456789abcdef-01', 'tracestate' => 'vendor=value')
    OpenTelemetry::Context.with_current(context) do
      @tracer.in_span('request') do |span|
        carrier = {}
        propagator.inject(carrier)
        assert_equal '0123456789abcdef0123456789abcdef', span.context.hex_trace_id
        assert_equal 'vendor=value', carrier['tracestate']
        assert_match span.context.hex_span_id, carrier['traceparent']
      end
    end
    span = @exporter.finished_spans.first
    assert_equal '0123456789abcdef', span.hex_parent_span_id
    assert span.parent_span_is_remote
  end

  def test_exception_is_recorded_and_context_restored
    error = assert_raises(RuntimeError) { @tracer.in_span('failure') { raise 'failure' } }
    assert_equal 'failure', error.message
    span = @exporter.finished_spans.first
    assert_equal 'exception', span.events.first.name
    assert_equal OpenTelemetry::Trace::Status::ERROR, span.status.code
    assert_equal OpenTelemetry::Context::ROOT, OpenTelemetry::Context.current
  end

  def test_baggage_and_rack_header_normalization
    baggage = OpenTelemetry::Baggage.set_value('tenant', 'legacy')
    assert_equal({ 'tenant' => 'legacy' }, OpenTelemetry::Baggage.values(context: baggage))
    getter = OpenTelemetry::Common::Propagation.rack_env_getter
    assert_equal ['traceparent'], getter.keys('HTTP_TRACEPARENT' => 'value')
    assert_equal 'value', getter.get({ 'HTTP_TRACEPARENT' => 'value' }, 'traceparent')
  end

  def test_context_isolated_between_fibers_and_threads
    key = OpenTelemetry::Context.create_key('test')
    OpenTelemetry::Context.with_value(key, 'parent') do
      assert_nil Fiber.new { OpenTelemetry::Context.value(key) }.resume
      assert_nil Thread.new { OpenTelemetry::Context.value(key) }.value
      assert_equal 'parent', OpenTelemetry::Context.value(key)
    end
  end

  def test_batch_flush_and_shutdown
    provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    exporter = @export::InMemorySpanExporter.new
    provider.add_span_processor(@export::BatchSpanProcessor.new(exporter, start_thread_on_boot: false))
    provider.tracer('batch').in_span('batched') {}
    assert_empty exporter.finished_spans
    assert_equal @export::SUCCESS, provider.force_flush(timeout: 1)
    assert_equal ['batched'], exporter.finished_spans.map(&:name)
    assert_equal @export::SUCCESS, provider.shutdown(timeout: 1)
    stopped = true
  ensure
    provider.shutdown if provider && !stopped
  end

  def test_explicit_options_preserve_nil_and_reject_unknown_keys
    assert_raises(ArgumentError) { @provider.tracer('invalid', unknown: true) }
    assert_raises(ArgumentError) { OpenTelemetry.error_handler.call(unknown: true) }
    exporter = @export::InMemorySpanExporter.new(recording: false)
    assert_equal @export::SUCCESS, exporter.export([], timeout: nil)
    assert_empty exporter.finished_spans
  end

  def test_numeric_and_array_attributes
    attributes = { 'integer' => 42, 'large' => 2**80, 'float' => 1.5, 'strings' => %w[one two], 'numbers' => [1, 2.0] }
    @tracer.in_span('attributes', attributes: attributes) {}
    assert_equal attributes, @exporter.finished_spans.first.attributes
  end

  def test_span_limits_and_explicit_timestamps
    @provider.span_limits = OpenTelemetry::SDK::Trace::SpanLimits.new(attribute_count_limit: 2, event_count_limit: 1)
    span = @tracer.start_span('limited', start_timestamp: Time.at(2))
    span.add_attributes('one' => 1, 'two' => 2, 'three' => 3)
    span.add_event('first')
    span.add_event('second')
    span.finish(end_timestamp: Time.at(3))
    data = @exporter.finished_spans.first
    assert_equal 2, data.attributes.size
    assert_equal ['second'], data.events.map(&:name)
    assert_equal 2_000_000_000, data.start_timestamp
    assert_equal 3_000_000_000, data.end_timestamp
  end

  def test_monotonic_timeout_and_zero_timeout
    utilities = OpenTelemetry::Common::Utilities
    before = utilities.timeout_timestamp
    sleep 0.01
    after = utilities.timeout_timestamp
    assert_operator after, :>, before
    assert_operator utilities.maybe_timeout(1, before), :<, 1
    assert_equal 0, utilities.maybe_timeout(0, before)
    assert_equal 0, utilities.maybe_timeout(Float::NAN, before)
    assert_nil utilities.maybe_timeout(nil, before)
  end

  def test_proxy_provider_preserves_scope_options
    proxy = OpenTelemetry::Internal::ProxyTracerProvider.new
    tracer = proxy.tracer(name: 'proxy', version: '1.0', attributes: { 'scope' => 'proxy' })
    proxy.delegate = @provider
    tracer.in_span('delegated') {}
    scope = @exporter.finished_spans.first.instrumentation_scope
    assert_equal 'proxy', scope.name
    assert_equal({ 'scope' => 'proxy' }, scope.attributes)
  end

  def test_resource_defaults_and_immutable_keys
    resource = OpenTelemetry::SDK::Resources::Resource.default
    attributes = Hash[resource.attribute_enumerator.to_a]
    assert_equal RUBY_VERSION, attributes['process.runtime.version']
    assert_equal Process.pid, attributes['process.pid']
    key = 'mutable'.dup
    resource = OpenTelemetry::SDK::Resources::Resource.create(key => 42)
    key.replace('changed')
    assert_equal({ 'mutable' => 42 }, Hash[resource.attribute_enumerator.to_a])
  end

  def test_ratio_sampler_and_missing_required_options
    samplers = OpenTelemetry::SDK::Trace::Samplers
    sampler = samplers.trace_id_ratio_based(0)
    result = sampler.should_sample?(trace_id: OpenTelemetry::Trace.generate_trace_id,
                                    parent_context: OpenTelemetry::Context::ROOT,
                                    name: 'drop', kind: :internal, links: nil, attributes: nil)
    refute_predicate result, :sampled?
    assert_raises(ArgumentError) { samplers.parent_based }
  end

  def test_forwarding_logger_preserves_lazy_blocks
    output = StringIO.new
    logger = OpenTelemetry::SDK::ForwardingLogger.new(Logger.new(output), level: 'warn')
    called = false
    logger.debug { called = true }
    logger.error { 'legacy error' }
    refute called
    assert_match 'legacy error', output.string
  end

  def test_package_metadata_accepts_current_interpreter
    require 'rubygems'
    %w[api common registry sdk semantic_conventions].each do |component|
      root = File.expand_path('../..', File.dirname(__FILE__))
      path = Dir[File.join(root, component, '*.gemspec')].first
      spec = Gem::Specification.load(path)
      refute_nil spec
      assert spec.required_ruby_version.satisfied_by?(Gem::Version.new(RUBY_VERSION.dup))
    end
  end
end
