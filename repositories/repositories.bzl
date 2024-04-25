"""Rules to load all dependencies of this project."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# buildifier: disable=function-docstring
def repositories():
    maybe(
        http_archive,
        name = "rules_python",
        url = "https://github.com/bazelbuild/rules_python/archive/0.27.1.tar.gz",
        strip_prefix = "rules_python-0.27.1",
        sha256 = "e85ae30de33625a63eca7fc40a94fea845e641888e52f32b6beea91e8b1b2793",
    )

    maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.6.0/bazel-skylib-1.6.0.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.6.0/bazel-skylib-1.6.0.tar.gz",
        ],
        sha256 = "41449d7c7372d2e270e8504dfab09ee974325b0b40fdd98172c7fbe257b8bcc9",
    )
