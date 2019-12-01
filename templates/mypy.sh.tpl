#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
  local output="{OUTPUT}"

  # TODO(Jonathon): Consider UX improvements using https://mypy.readthedocs.io/en/stable/command_line.html#configuring-error-messages

  {MYPY_EXE} --bazel --package-root . {SRCS} 2>&1 | tee "${output}"
}

main "$@"