load("@mypy_integration_pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

alias(
    name = "mypy",
    actual = requirement("mypy"),
    visibility = ["//:__pkg__"],
)

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--resolver=backtracking"],
    requirements_in = "requirements.in",
    requirements_txt = "requirements.txt",
)

exports_files(
    ["requirements.txt"],
    visibility = ["//:__pkg__"],
)
