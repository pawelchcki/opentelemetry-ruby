# Legacy trace SDK verification

This fork backports the official trace API and SDK to MRI Ruby 1.9.3 and later.
The legacy runtime matrix targets Linux on x86-64. Ruby 1.9.3 and 2.0 use
standard-library DL bindings to the Linux monotonic clock; modern Ruby keeps
using `Process.clock_gettime`.

The compatible gems are `opentelemetry-api`, `opentelemetry-common`,
`opentelemetry-registry`, `opentelemetry-sdk`, and
`opentelemetry-semantic_conventions`. Metrics, logs, contrib instrumentation,
and network exporters retain their separate upstream Ruby requirements.
The tests exercise actual trace generation and exporter interfaces using the
SDK's in-memory exporter; they do not certify OTLP transport on legacy Ruby.

## Install the fork

Use a Bundler version compatible with your application Ruby and select all five
core gems from this repository so dependencies cannot resolve to modern-only
upstream releases:

```ruby
git 'https://github.com/pawelchcki/opentelemetry-ruby.git',
    :branch => 'legacy',
    :glob => '{api,common,registry,sdk,semantic_conventions}/*.gemspec' do
  gem 'opentelemetry-api'
  gem 'opentelemetry-common'
  gem 'opentelemetry-registry'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-semantic_conventions'
end
```

Logger is resolved as a normal dependency on every Ruby version. Its 1.3.0
release is excluded because it declares Ruby >= 0 but uses Ruby 2.3 syntax;
legacy applications can use Logger 1.2.8.1 and modern applications can use newer
compatible releases.

Public calls still accept keyword-style options on modern Ruby and option
hashes on Ruby 1.9.3. Explicit nil values, required options, unknown-option
errors, and lazy defaults are preserved.

## Run the matrix

Install Bazelisk or Bazel 9.2.0. No host Ruby or Bundler installation is needed.
The pinned [rules_stests](https://github.com/pawelchcki/rules_stests) dependency
supplies extracted MRI runtime images, and Minitest 5.10.3 is fetched with a
fixed SHA-256 checksum.

```sh
bazel test //verification:legacy_suite
```

This runs one independent test target for each MRI series: 1.9.3, 2.0 through
2.7, 3.0 through 3.4, and 4.0. Run a single interpreter with:

```sh
bazel test //verification:ruby_1_9_3_test
```

The checks cover span parenting, W3C propagation, baggage, fiber and thread
context isolation, exceptions, resources, instrumentation scopes, sampling,
attribute limits, timestamps, batch flush/shutdown, logger blocks, and gem
metadata. The repository defaults to local execution. With BuildBuddy
credentials in your user Bazel configuration, remote execution is available:

```sh
bazel test --config=buildbuddy //verification:legacy_suite
```

Remote execution uploads the test source and inputs to the configured workers.
Upstream gem unit tests, RuboCop, and YARD still run separately on modern Ruby.
