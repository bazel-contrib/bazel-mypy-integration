#!/usr/bin/env bash
#
# Integration tests that execute, with `bazel build` and `bazel test`,
# build rules defined in the repo's /test directory.

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# shellcheck source=/dev/null
source "${dir}"/test_runner.sh
# shellcheck source=/dev/null
source "${dir}"/test_helper.sh

runner=$(get_test_runner "${1:-local}")

# Obviously doesn't test the integration's functionality, just the basics of repo's Bazel
# workspace setup, a prerequisite to testing the integration's functionality.
test_ok_running_bazel_version() {
  action_should_succeed version
}

test_ok_on_valid_imported_mypy_typings() {
  action_should_succeed build --verbose_failures --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:correct_imported_mypy_typings
}

test_ok_on_valid_imported_mypy_test() {
  action_should_succeed test //test:correct_imported_mypy_test
}

test_ok_on_valid_mypy_typings() {
  action_should_succeed build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:correct_mypy_typings
}

test_ok_on_valid_mypy_test() {
  action_should_succeed test //test:correct_mypy_test
}

test_ok_on_empty_py_library() {
  action_should_succeed build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:empty_srcs_lib
}

# Test for regression originally introduced in https://github.com/thundergolfer/bazel-mypy-integration/pull/16/files
test_ok_for_package_roots_regression() {
  action_should_succeed build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test/foo:foo
}

test_ok_buildifier() {
  action_should_succeed run //tools/buildifier:buildifier.check
}

test_fails_on_broken_mypy_typings() {
  action_should_fail build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:broken_mypy_typings
}

test_fails_on_broken_imported_mypy_test() {
  action_should_fail test //test:broken_imported_mypy_test
}

test_fails_on_broken_imported_mypy_typings() {
  action_should_fail build --verbose_failures --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:broken_imported_mypy_typings
}

test_fails_on_broken_mypy_test() {
  action_should_fail test //test:broken_mypy_test
}

test_fails_on_empty_mypy_test() {
  action_should_fail test //test:empty_mypy_test
}

main() {
  $runner test_ok_running_bazel_version
  $runner test_ok_on_valid_mypy_typings
  $runner test_ok_for_package_roots_regression
  $runner test_ok_on_valid_imported_mypy_typings
  $runner test_ok_on_valid_imported_mypy_test
  $runner test_ok_on_valid_mypy_test
  $runner test_ok_on_empty_py_library
  $runner test_ok_buildifier

  $runner test_fails_on_broken_imported_mypy_typings
  $runner test_fails_on_broken_imported_mypy_test
  $runner test_fails_on_broken_mypy_typings
  $runner test_fails_on_broken_mypy_test
  $runner test_fails_on_empty_mypy_test
}

main "$@"
