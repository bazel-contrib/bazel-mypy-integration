#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
  local output="{OUTPUT}"

  # TODO(Jonathon): Consider UX improvements using https://mypy.readthedocs.io/en/stable/command_line.html#configuring-error-messages

  export MYPYPATH="{MYPYPATH_PATH}"

  echo "${MYPYPATH}"

  {MYPY_EXE} {VERBOSE_OPT} \
    --bazel \
    --package-root . \
    --config-file {MYPY_INI_PATH} \
    --cache-map {CACHE_MAP_TRIPLES} -- {SRCS} 2>&1 | tee "${output}"
}

main "$@"