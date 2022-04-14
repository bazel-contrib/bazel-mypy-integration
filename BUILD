load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_python//:version.bzl", "version")

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

filegroup(
    name = "distribution",
    srcs = [
        "BUILD",
        "LICENSE",
        "config.bzl",
        "current_mypy_version.txt",
        "mypy.bzl",
        "rules.bzl",
        "//mypy:distribution",
        "//repositories:distribution",
        "//templates:distribution",
        "//third_party:distribution",
    ],
)

version = "0.2.1"

# Build the artifact to put on the github release page.
pkg_tar(
    name = "bazel_mypy_integration-{version}".format(version = version),
    srcs = [
        ":distribution",
    ],
    extension = "tar.gz",
    # It is all source code, so make it read-only.
    mode = "0444",
    # Make it owned by root
    owner = "0.0",
    package_dir = ".",
    strip_prefix = ".",
)
