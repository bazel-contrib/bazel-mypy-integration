"""Rules to load all dependencies of this project."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# buildifier: disable=function-docstring
def repositories():
    excludes = native.existing_rules().keys()

    rules_python_version = "0.12.0"

    if "rules_python" not in excludes:
        http_archive(
            name = "rules_python",
            url = "https://github.com/bazelbuild/rules_python/archive/{version}.tar.gz".format(version = rules_python_version),
            strip_prefix = "rules_python-{version}".format(version = rules_python_version),
            sha256 = "b593d13bb43c94ce94b483c2858e53a9b811f6f10e1e0eedc61073bd90e58d9c",
        )

    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz",
            ],
            sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        )
