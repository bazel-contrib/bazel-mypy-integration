load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")

package(default_visibility = ["//visibility:private"])

buildifier(
    name = "buildifier.check",
    lint_mode = "warn",
    mode = "diff",
)

buildifier(
    name = "buildifier",
    lint_mode = "fix",
    mode = "fix",
)

licenses(["notice"])  # MIT

exports_files([
    "LICENSE",
    "version.bzl",
])

compile_pip_requirements(
    name = "requirements",
    requirements_in = "current_mypy_version.txt",
    requirements_txt = "requirements-locked.txt",
)