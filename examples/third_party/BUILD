load("@my_deps//:requirements.bzl", "requirement")
load("@mypy_integration//:mypy.bzl", "mypy_test")

py_binary(
    name = "uses-deps",
    srcs = ["uses-deps.py"],
    deps = [
        requirement("types_python_dateutil"),
    ],
)

mypy_test(
    name = "uses_deps_mypy",
    deps = [":uses-deps"],
)
