load("@my_deps//:requirements.bzl", "requirement")

py_binary(
    name = "mypy",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        requirement("mypy"),
        # Transitive deps determined by looking at: https://github.com/python/mypy/blob/master/mypy-requirements.txt
        requirement("typing_extensions"),
        requirement("mypy_extensions"),
        requirement("typed_ast"),
    ]
)