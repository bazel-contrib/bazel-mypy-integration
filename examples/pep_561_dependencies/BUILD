load("@my_deps//:requirements.bzl", "requirement")
load("@mypy_integration//:rules.bzl", "mypy_stubs")

py_binary(
    name = "use_httpx",
    srcs = glob(["*.py"]),
    main = "use_httpx.py",
    python_version = "PY3",
    deps = [
        requirement("httpx"),
    ],
)
