load("@buildifier_prebuilt//:rules.bzl", "buildifier")

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
