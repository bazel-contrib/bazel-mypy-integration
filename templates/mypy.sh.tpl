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
  local mypy_ini_path

  declare -r report_file="{OUTPUT}"
  declare -r root="{MYPY_ROOT}/"
  declare -r mypy_ini_path="{MYPY_INI_PATH}"

  mypy="{MYPY_EXE}"
  stdlib_metadata_triples_param_file="{STDLIB_METADATA_TRIPLES_PARAM_FILE}"

  # TODO(Jonathon): Consider UX improvements using https://mypy.readthedocs.io/en/stable/command_line.html#configuring-error-messages

  export MYPYPATH=".:{MYPYPATH_PATH}"

  # Workspace rules run in a different location from aspect rules. Here we
  # normalize if the external source isn't found.
  if [ ! -f $mypy ]; then
    mypy=${mypy#${root}}
  fi

  echo ============================ cd $PWD

  if [ -f "$stdlib_metadata_triples_param_file" ]; then
    # Add the '@' to signify to mypy that this is a param file to read. See
    # https://mypy.readthedocs.io/en/latest/running_mypy.html#reading-a-list-of-files-from-a-file
    stdlib_metadata_triples_param_file="@${stdlib_metadata_triples_param_file}"
  else
    stdlib_metadata_triples_param_file=""
  fi

  set +o errexit
  mypy_args=(
    {VERBOSE_OPT}
    # This enables bazel-specific settings in mypy.
    # See: https://github.com/python/mypy/search?q=bazel&unscoped_q=bazel
    --bazel
    # The --package-root arguments:
    {PACKAGE_ROOTS}
    --custom-typeshed-dir {CUSTOM_TYPESHED_DIR}
    # Namespace packages are packages that do not contain an __init__.py file, which is the norm for
    # some codebases. This flag enables mypy to discover packages without the __init__ files.
    --namespace-packages
    # Pre-canned mypy options:
    --config-file $mypy_ini_path
    # Set of triples representing where mypy should read/store cache entries for each source file,
    # of the form: "path/to/src.py path/to/src.meta.json path/to/src.data.json".
    --cache-map @{CACHE_MAP_TRIPLES_PARAM_FILE}
    # NOTE: The placement of the stdlib_metadata_triples_param_file here is very important, since it
    # must come after the --cache-map flag above. Nothing else can come after --cache-map, except
    # finally the module/src arguments.
    $stdlib_metadata_triples_param_file
    # The set of modules under test:
    {MODULES}
    # The set of source files under test:
    -- {SRCS}
  )

  output=$("${mypy}" "${mypy_args[@]}" 2>&1)
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
