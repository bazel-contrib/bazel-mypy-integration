load("@my_mypy_deps//:requirements.bzl", "requirement")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--resolver=backtracking"],
    requirements_in = "mypy_requirements.in",
    requirements_txt = "mypy_requirements.txt",
)

exports_files([
    "mypy.ini",
    "mypy_requirements.txt",
])

alias(
    name = "mypy",
    actual = requirement("mypy"),
    visibility = ["//visibility:public"],
)
