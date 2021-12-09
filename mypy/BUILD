load("@mypy_integration_pip_deps//:requirements.bzl", "requirement")

py_binary(
    name = "mypy",
    srcs = ["main.py"],
    main = "main.py",
    python_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [
        requirement("mypy"),
    ],
)

filegroup(
    name = "distribution",
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)
