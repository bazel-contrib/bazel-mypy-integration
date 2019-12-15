dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. "${dir}"/test_runner.sh
. "${dir}"/test_helper.sh

runner=$(get_test_runner "${1:-local}")

test_ok_on_valid_mypy_typings() {
  # TODO(Jonathon): Implement
  action_should_succeed build --aspects //:mypy.bzl%mypy_aspect --output_groups=foo //test:correct_mypy_typings
#  action_should_succeed build //test:correct_mypy_typings
}

$runner test_ok_on_valid_mypy_typings