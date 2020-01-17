#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
  local output
  local report_file
  local status
  report_file="{OUTPUT}"

  # TODO(Jonathon): Consider UX improvements using https://mypy.readthedocs.io/en/stable/command_line.html#configuring-error-messages

  export MYPYPATH="$(pwd):{MYPYPATH_PATH}"

  set +o errexit
  output=$({MYPY_EXE} {VERBOSE_OPT} --bazel --package-root . --config-file {MYPY_INI_PATH} --cache-map {CACHE_MAP_TRIPLES} -- {SRCS} 2>&1)
  status=$?
  set -o errexit

  echo "${output}" > "${report_file}"
  if [[ $status -ne 0 ]]; then
    echo "${output}" # Show MyPy's error to end-user via Bazel's console logging
    exit 1
  fi

}

main "$@"
