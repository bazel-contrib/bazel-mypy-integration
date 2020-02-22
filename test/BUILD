package(default_testonly = 1)

load("//:mypy.bzl", "mypy_test")

py_library(
    name = "broken_mypy_typings",
    srcs = ["broken_mypy_typings.py"],
    srcs_version = "PY3",
)

py_library(
    name = "correct_mypy_typings",
    srcs = ["correct_mypy_typings.py"],
    srcs_version = "PY3",
)

mypy_test(
    name = "correct_mypy_test",
    deps = [":correct_mypy_typings"],
)

mypy_test(
    name = "broken_mypy_test",
    deps = [":broken_mypy_typings"],
)

mypy_test(
    name = "empty_mypy_test",
)
