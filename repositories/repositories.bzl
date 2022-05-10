"""Rules to load all dependencies of this project."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

versions = struct(
    bazel_skylib = "1.0.2",
    rules_python = "0.8.1",
)

# buildifier: disable=function-docstring
def repositories():
    maybe(
        http_archive,
        name = "rules_python",
        url = "https://github.com/bazelbuild/rules_python/archive/{}.tar.gz".format(versions.rules_python),
        strip_prefix = "rules_python-{}".format(versions.rules_python),
        sha256 = "cdf6b84084aad8f10bf20b46b77cb48d83c319ebe6458a18e9d2cebf57807cdd",
    )

    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/{0}/bazel-skylib-{0}.tar.gz".format(versions.bazel_skylib),
            "https://github.com/bazelbuild/bazel-skylib/releases/download/{0}/bazel-skylib-{0}.tar.gz".format(versions.bazel_skylib),
        ],
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    )

    maybe(
        http_archive,
        name = "aspect_rules_py",
        sha256 = "874c5ae0e763e0326c6f45f3a5d12d00a751fc7c658e02271b6fa89f15f38862",
        strip_prefix = "rules_py-main",
        urls = ["https://github.com/aspect-build/rules_py/archive/refs/heads/main.zip"],
    )
