load("@rules_python//python:pip.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    src = "requirements.in",
    extra_args = ["--resolver=backtracking"],
    requirements_txt = "requirements.txt",
)
