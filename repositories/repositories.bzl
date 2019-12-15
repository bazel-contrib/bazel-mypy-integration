"""Rules to load all dependencies of this project."""

load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
    "http_file",
)

def repositories():
    excludes = native.existing_rules().keys()

    rules_python_version = "7b222cfdb4e59b9fd2a609e1fbb233e94fdcde7c"

    if "rules_python" not in excludes:
        http_archive(
            name = "rules_python",
            sha256 = "d2865e2ce23ee217aaa408ddaa024ca472114a6f250b46159d27de05530c75e3",
            strip_prefix = "rules_python-{version}".format(version = rules_python_version),
            url = "https://github.com/bazelbuild/rules_python/archive/{version}.tar.gz".format(version = rules_python_version),
        )

    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            ],
            sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
        )
