load("@my_deps//:requirements.bzl", "requirement")
load("@mypy_integration//:rules.bzl", "mypy_stubs")

mypy_stubs(
    name = "stubs",
    srcs = glob(["stubs/*.pyi"]),
)

py_binary(
    name = "parse_name",
    srcs = glob(["*.py"]),
    main = "parse_name.py",
    python_version = "PY3",
    deps = [
        ":stubs",
        requirement("parse"),
    ],
)
