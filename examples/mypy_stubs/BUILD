load("@my_deps//:requirements.bzl", "requirement")
load("@mypy_integration//:rules.bzl", "mypy_stubs")

mypy_stubs(
    name = "stubs",
    srcs = glob(["stubs/*.pyi"]),
)

mypy_stubs(
    name = "parse_name_stubs",
    srcs = glob(["*.pyi"]),
)

py_binary(
    name = "parse_name",
    srcs = glob(["*.py"]),
    deps = [
        ":stubs",
        ":parse_name_stubs",
        requirement("parse"),
    ],
    main = "parse_name.py",
    python_version = "PY3",
)