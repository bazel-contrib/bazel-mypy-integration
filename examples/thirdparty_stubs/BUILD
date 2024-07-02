load("@my_deps//:requirements.bzl", "requirement")

py_library(
    name = "lib",
    srcs = ["uses_thirdparty_stubs.py"],
    deps = [
        requirement("typer"),
    ],
)

py_binary(
    name = "main",
    srcs = glob(["*.py"]),
    main = "uses_thirdparty_stubs.py",
    python_version = "PY3",
    deps = [
        requirement("typer"),
    ],
)

py_test(
    name = "main_test",
    srcs = glob(["*.py"]),
    main = "uses_thirdparty_stubs.py",
    python_version = "PY3",
    deps = [
        ":lib",
    ],
)
