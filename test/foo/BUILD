load("@rules_python//python:defs.bzl", "py_library")

py_library(
    name = "foo",
    srcs = ["bar.py"],
    srcs_version = "PY3",
    visibility = ["//test:__subpackages__"],
    deps = [
        "//test/types",
    ],
)
