# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

lib = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentelemetry/sdk/version'

Gem::Specification.new do |spec|
  spec.name        = 'opentelemetry-sdk'
  spec.version     = OpenTelemetry::SDK::VERSION.dup
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
  spec.add_dependency 'opentelemetry-api', '~> 1.1'
  spec.add_dependency 'opentelemetry-common', '~> 0.20'
  spec.add_dependency 'opentelemetry-registry', '~> 0.2'

  # This is an intentionally loose dependency, since we want to be able to
  # release new versions of opentelemetry-semantic_conventions without requiring
  # a new SDK release. The requirements of the SDK have been satisfied since the
  # initial release of opentelemetry-semantic_conventions, so we feel it is safe.
  spec.add_dependency 'opentelemetry-semantic_conventions'

  if spec.respond_to?(:metadata)
    spec.metadata['changelog_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}/file/CHANGELOG.md"
    spec.metadata['source_code_uri'] = "https://github.com/open-telemetry/opentelemetry-ruby/tree/#{spec.name}/v#{spec.version}/sdk"
    spec.metadata['bug_tracker_uri'] = 'https://github.com/open-telemetry/opentelemetry-ruby/issues'
    spec.metadata['documentation_uri'] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  end
end
