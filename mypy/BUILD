load("@mypy_integration_pip_deps//:requirements.bzl", "requirement")
load("//:mypy.bzl", "mypy_stdlib_cache_library")

py_binary(
    name = "mypy",
    srcs = ["main.py"],
    main = "main.py",
    python_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [
        requirement("mypy"),
        # Transitive deps determined by looking at: https://github.com/python/mypy/blob/master/mypy-requirements.txt
        requirement("typing_extensions"),
        requirement("mypy_extensions"),
        requirement("typed_ast"),
    ],
)

filegroup(
    name = "distribution",
    srcs = glob(["**"]),
    visibility = ["//:__pkg__"],
)

mypy_stdlib_cache_library(
    # This target represents the singleton collection of typeshed stdlib stub files. The details of
    # this target are not visible here, but instead part of its implementation (see mypy.bzl).
    #
    # There is only one of this target, and it is an implicit dependency of the mypy aspect
    # machinery.
    name = "mypy_stdlib_cache",
    visibility = ["//visibility:public"],
)
