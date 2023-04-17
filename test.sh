#!/usr/bin/env bash
#
# Root test script that merely dispatches to other test running scripts.

set -euo pipefail

test_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/test/shell

bazel clean --expunge

echo "Running integration tests against repo's Bazel workspace..."
# shellcheck source=/dev/null
source "${test_dir}"/test_mypy.sh
