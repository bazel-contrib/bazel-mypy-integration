load("//:mypy.bzl", "mypy_test")

package(default_testonly = 1)

py_library(
    name = "empty_srcs_lib",
    srcs = [],
    srcs_version = "PY3",
)

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

py_library(
    name = "correct_imported_mypy_typings",
    srcs = [
        "correct_imported_typings.py",
        ":correct_generated_mypy_typings",
    ],
    srcs_version = "PY3",
)

py_library(
    name = "broken_imported_mypy_typings",
    srcs = [
        "broken_imported_typings.py",
        ":broken_generated_mypy_typings",
    ],
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
    tags = ["manual"],
)

mypy_test(
    name = "correct_imported_mypy_test",
    deps = [":correct_imported_mypy_typings"],
)

mypy_test(
    name = "broken_imported_mypy_test",
    deps = [":broken_imported_mypy_typings"],
)

genrule(
    name = "correct_generated_mypy_typings",
    outs = ["correct_generated.py"],
    cmd =
        ("echo -e '" +
         "from typing import Callable\n\n" +
         "def thrice(i: int, next_: Callable[[int], int]) -> int:\n" +
         "   return next_(next_(next_(i)))\n' > $@"),
    local = True,
)

genrule(
    name = "broken_generated_mypy_typings",
    outs = ["broken_generated.py"],
    cmd =
        ("echo -e '" +
         "from typing import Callable\n\n" +
         "def thrice(i: int, next_: Callable[[int], int]) -> str:\n" +
         "   return next_(next_(next_(i)))\n' > $@"),
    local = True,
)
