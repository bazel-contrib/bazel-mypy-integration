#!/usr/bin/env bash

{VERBOSE_BASH}
set -o errexit
set -o nounset
set -o pipefail

main() {
  local output
  local report_file
  local status
  local root
  local mypy

  report_file="{OUTPUT}"
  root="{MYPY_ROOT}/"
  mypy="{MYPY_EXE}"

  # TODO(Jonathon): Consider UX improvements using https://mypy.readthedocs.io/en/stable/command_line.html#configuring-error-messages

  export MYPYPATH="$(pwd):{MYPYPATH_PATH}"

  # Workspace rules run in a different location from aspect rules. Here we
  # normalize if the external source isn't found.
  if [ ! -f $mypy ]; then
    mypy=${mypy#${root}}
  fi

  set +o errexit
  output=$($mypy {VERBOSE_OPT} --bazel {PACKAGE_ROOTS} --config-file {MYPY_INI_PATH} --cache-map {CACHE_MAP_TRIPLES} -- {SRCS} 2>&1)
  status=$?
  set -o errexit

  if [ ! -z "$report_file" ]; then
    echo "${output}" > "${report_file}"
  fi

  if [[ $status -ne 0 ]]; then
    echo "${output}" # Show MyPy's error to end-user via Bazel's console logging
    exit 1
  fi

}

main "$@"
