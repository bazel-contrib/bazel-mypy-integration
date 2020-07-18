dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. "${dir}"/test_runner.sh
. "${dir}"/test_helper.sh

runner=$(get_test_runner "${1:-local}")

test_ok_on_valid_mypy_typings() {
  action_should_succeed build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:correct_mypy_typings
}

# Test for regression originally introduced in https://github.com/thundergolfer/bazel-mypy-integration/pull/16/files
test_ok_for_package_roots_regression() {
  action_should_succeed build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test/foo:foo
}

test_fails_on_broken_mypy_typings() {
  action_should_fail build --aspects //:mypy.bzl%mypy_aspect --output_groups=mypy //test:broken_mypy_typings
}

test_ok_on_valid_mypy_test() {
  action_should_succeed test //test:correct_mypy_test
}

test_fails_on_broken_mypy_test() {
  action_should_fail test //test:broken_mypy_test
}

test_fails_on_empty_mypy_test() {
  action_should_fail test //test:empty_mypy_test
}

$runner test_ok_on_valid_mypy_typings
$runner test_ok_for_package_roots_regression
$runner test_fails_on_broken_mypy_typings
$runner test_ok_on_valid_mypy_test
$runner test_fails_on_broken_mypy_test
$runner test_fails_on_empty_mypy_test
