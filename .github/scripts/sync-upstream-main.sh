#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

upstream_repository=${UPSTREAM_REPOSITORY:-https://github.com/open-telemetry/opentelemetry-ruby.git}
fork_repository=${FORK_REPOSITORY:-git@github.com:pawelchcki/opentelemetry-ruby.git}
sync_directory=$(mktemp -d)
trap 'rm -rf "$sync_directory"' EXIT

git init --bare --quiet "$sync_directory"
git -C "$sync_directory" fetch --no-tags "$upstream_repository" \
  refs/heads/main:refs/heads/upstream/main
git -C "$sync_directory" fetch --no-tags "$fork_repository" \
  refs/heads/main:refs/heads/fork/main

upstream_commit=$(git -C "$sync_directory" rev-parse refs/heads/upstream/main)
fork_commit=$(git -C "$sync_directory" rev-parse refs/heads/fork/main)
if [[ "$upstream_commit" == "$fork_commit" ]]; then
  echo "main already matches upstream: $upstream_commit"
  exit 0
fi

if ! git -C "$sync_directory" merge-base --is-ancestor "$fork_commit" "$upstream_commit"; then
  echo 'Refusing to sync: fork main is not an ancestor of upstream main.' >&2
  exit 1
fi

# A normal push also rejects a concurrent update that would cease to fast-forward.
git -C "$sync_directory" push "$fork_repository" \
  refs/heads/upstream/main:refs/heads/main
echo "Synced main to upstream: $upstream_commit"
