#!/usr/bin/env bash
set -euo pipefail

runtime="$1"
abi="$2"
minitest="${3%/*}"
test_file="$4"

libraries="$runtime/usr/local/lib:$runtime/lib/x86_64-linux-gnu:$runtime/usr/lib/x86_64-linux-gnu"
ruby_libraries="$minitest:$runtime/usr/local/lib/ruby/$abi:$runtime/usr/local/lib/ruby/$abi/x86_64-linux:$runtime/usr/local/lib/ruby/$abi/x86_64-linux-gnu"
for library in "$runtime"/usr/local/lib/ruby/gems/"$abi"/gems/*/lib; do
  if [[ -d "$library" ]]; then
    ruby_libraries="$ruby_libraries:$library"
  fi
done

export RUBYLIB="$ruby_libraries"
export LD_LIBRARY_PATH="$libraries"
exec "$runtime/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" \
  --library-path "$libraries" "$runtime/usr/local/bin/ruby" --disable-gems "$test_file"
