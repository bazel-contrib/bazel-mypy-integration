#!/usr/bin/env bash
#
# Test helper functions for  bazel-mypy-integration integration tests.
# Credit: https://github.com/bazelbuild/rules_scala/blob/master/test/shell/test_helper.sh

action_should_succeed() {
  # runs the tests locally
  set +e
  TEST_ARG=$@
  OUTPUT=$(bazel $TEST_ARG)
  RESPONSE_CODE=$?
  if [ $RESPONSE_CODE -eq 0 ]; then
    exit 0
  else
    # Bazel may report useful error information to stdout.
    if [[ -n $OUTPUT ]]; then
        echo -e "$OUTPUT"
    fi
    echo -e "${RED} \"bazel $TEST_ARG\" should have passed but failed. $NC"
    exit -1
  fi
}

action_should_fail() {
  # runs the tests locally
  set +e
  TEST_ARG=$@
  OUTPUT=$(bazel $TEST_ARG)
  RESPONSE_CODE=$?
  if [ $RESPONSE_CODE -eq 0 ]; then
    echo -e "${RED} \"bazel $TEST_ARG\" should have failed but passed. $NC"
    exit -1
  else
    exit 0
  fi
}

test_expect_failure_with_message() {
  set +e

  expected_message=$1
  test_filter=$2
  test_command=$3

  command="bazel test --nocache_test_results --test_output=streamed ${test_filter} ${test_command}"
  output=$(${command} 2>&1)

  echo ${output} | grep "$expected_message"
  if [ $? -ne 0 ]; then
    echo "'bazel test ${test_command}' should have logged \"${expected_message}\"."
        exit 1
  fi
  if [ "${additional_expected_message}" != "" ]; then
    echo ${output} | grep "$additional_expected_message"
    if [ $? -ne 0 ]; then
      echo "'bazel test ${test_command}' should have logged \"${additional_expected_message}\"."
          exit 1
    fi
  fi

  set -e
}

action_should_fail_with_message() {
  set +e
  MSG=$1
  TEST_ARG=${@:2}
  RES=$(bazel $TEST_ARG 2>&1)
  RESPONSE_CODE=$?
  echo $RES | grep -- "$MSG"
  GREP_RES=$?
  if [ $RESPONSE_CODE -eq 0 ]; then
    echo -e "${RED} \"bazel $TEST_ARG\" should have failed but passed. $NC"
    exit 1
  elif [ $GREP_RES -ne 0 ]; then
    echo -e "${RED} \"bazel $TEST_ARG\" should have failed with message \"$MSG\" but did not. $NC"
  else
    exit 0
  fi
}
