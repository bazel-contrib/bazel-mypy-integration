#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
  echo "foo" > "{OUTPUT}"
  echo "fuck"

  {MYPY_EXE} --bazel --package-root . {SRCS}
}

main "$@"