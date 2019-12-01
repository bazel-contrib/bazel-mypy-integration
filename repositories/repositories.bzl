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
