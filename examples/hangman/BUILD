load("@mypy_integration//:mypy.bzl", "mypy_test")

py_library(
    name = "third_layer",
    srcs = [
        "third_layer/third_layer.py",
    ],
    imports = ["third_layer"],
)

py_library(
    name = "third_layer_duplicate",
    srcs = [
        "third_layer/third_layer.py",
    ],
)

py_library(
    name = "hangman_tools",
    srcs = [
        "tools/hangman_tools.py",
        "tools/internal/hangman_tools_internal.py",
    ],
    imports = ["tools"],
    deps = [
        ":third_layer",
        ":third_layer_duplicate",
        "//fully_qualified:string_tools",
    ],
)

py_binary(
    name = "hangman",
    srcs = ["hangman.py"],
    main = "hangman.py",
    python_version = "PY3",
    deps = [
        ":hangman_tools",
    ],
)

mypy_test(
    name = "hangman_mypy",
    deps = [
        ":hangman_tools",
    ],
)
