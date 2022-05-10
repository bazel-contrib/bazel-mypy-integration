load("@mypy_integration_pip_deps//:requirements.bzl", "requirement")
load("@aspect_rules_py//py:defs.bzl", "py_binary")

py_binary(
    name = "mypy",
    srcs = ["main.py"],
    main = "main.py",
    visibility = ["//visibility:public"],
    deps = [
        "@mypy_integration_pip_deps_mypy//:wheel",
    ],
)
