load("@rules_python//python:pip.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--resolver=backtracking"],
    requirements_in = "requirements.in",
    requirements_txt = "requirements.txt",
)
