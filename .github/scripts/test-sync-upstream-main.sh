#!/usr/bin/env bash
# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fixture_directory=$(mktemp -d)
trap 'rm -rf "$fixture_directory"' EXIT

git init --quiet --initial-branch=main "$fixture_directory/source"
git -C "$fixture_directory/source" config user.name 'Sync test'
git -C "$fixture_directory/source" config user.email 'sync-test@example.invalid'
git -C "$fixture_directory/source" config commit.gpgsign false
git -C "$fixture_directory/source" commit --quiet --allow-empty -m initial
git clone --quiet --bare "$fixture_directory/source" "$fixture_directory/upstream.git"
git clone --quiet --bare "$fixture_directory/source" "$fixture_directory/fork.git"
export UPSTREAM_REPOSITORY="$fixture_directory/upstream.git"
export FORK_REPOSITORY="$fixture_directory/fork.git"

fork_head() { git -C "$FORK_REPOSITORY" rev-parse refs/heads/main; }
upstream_head() { git -C "$UPSTREAM_REPOSITORY" rev-parse refs/heads/main; }

initial_commit=$(fork_head)
bash "$script_directory/sync-upstream-main.sh"
[[ "$(fork_head)" == "$initial_commit" ]]
echo 'PASS: unchanged upstream is a no-op'

git -C "$fixture_directory/source" commit --quiet --allow-empty -m upstream-update
git -C "$fixture_directory/source" push --quiet "$UPSTREAM_REPOSITORY" main
bash "$script_directory/sync-upstream-main.sh"
[[ "$(fork_head)" == "$(upstream_head)" ]]
echo 'PASS: fork advances to the exact upstream commit'

git -C "$fixture_directory/source" checkout --quiet -b fork-divergence main
git -C "$fixture_directory/source" commit --quiet --allow-empty -m fork-only
git -C "$fixture_directory/source" push --quiet "$FORK_REPOSITORY" fork-divergence:main
fork_commit=$(fork_head)
if bash "$script_directory/sync-upstream-main.sh"; then
  echo 'FAIL: a diverged fork was accepted' >&2
  exit 1
fi
[[ "$(fork_head)" == "$fork_commit" ]]
echo 'PASS: divergence fails without changing fork main'
