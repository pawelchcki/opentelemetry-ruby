# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-api'
  spec.version     = OpenTelemetry::VERSION.dup
  spec.authors     = ['OpenTelemetry Authors']
  spec.email       = ['cncf-opentelemetry-contributors@lists.cncf.io']

  spec.summary     = 'A stats collection and distributed tracing framework'
  spec.description = 'A stats collection and distributed tracing framework'
  spec.homepage    = 'https://github.com/open-telemetry/opentelemetry-ruby'
  spec.license     = 'Apache-2.0'

  spec.files = ::Dir.glob('lib/**/*.rb') +
               ::Dir.glob('*.md') +
               ['LICENSE', '.yardopts']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.3'
  # Logger 1.3.0 declares Ruby >= 0 but contains Ruby 2.3-only syntax.
  spec.add_dependency 'logger', '>= 1.2.8.1', '!= 1.3.0'

  spec.add_development_dependency 'concurrent-ruby', '~> 1.3'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = "https://github.com/open-telemetry/opentelemetry-ruby/tree/#{spec.name}/v#{spec.version}/api"
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
