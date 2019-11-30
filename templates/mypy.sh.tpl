#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
  echo "fuck"

  local output="{OUTPUT}"

  {MYPY_EXE} --bazel --package-root . {SRCS} > "${output}"
}

main "$@"