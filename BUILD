load("@com_github_bazelbuild_buildtools//buildifier:def.bzl", "buildifier")

load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_python//:version.bzl", "version")

buildifier(
    name = "buildifier",
)

package(default_visibility = ["//visibility:private"])

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
        "mypy.bzl",
        "rules.bzl",
        "current_mypy_version.txt",
        "//mypy:distribution",
        "//repositories:distribution",
        "//templates:distribution",
        "//third_party:distribution",
    ],
)

version = "0.0.10"

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
