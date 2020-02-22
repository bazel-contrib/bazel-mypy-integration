load("@mypy_integration//:mypy.bzl", "mypy_test")

py_binary(
    name = "hangman",
    srcs = glob(["*.py"]),
    main = "hangman.py",
    python_version = "PY3",
    deps = [],
)

mypy_test(
    name = "hangman_mypy",
    deps = [
        ":hangman",
    ],
)
