load("@buildifier_prebuilt//:rules.bzl", "buildifier")

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
