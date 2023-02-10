#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="bazel-mypy-integration-${TAG}"
ARCHIVE="bazel-mypy-integration-$TAG.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

cat << EOF
WORKSPACE snippet:
\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "mypy_integration",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/thundergolfer/bazel-mypy-integration/releases/download/${TAG}/${ARCHIVE}",
)

load(
    "@mypy_integration//repositories:repositories.bzl",
    mypy_integration_repositories = "repositories",
)
mypy_integration_repositories()

load("@mypy_integration//:config.bzl", "mypy_configuration")
# Optionally pass a MyPy config file, otherwise pass no argument.
mypy_configuration("//tools/typing:mypy.ini")

load("@mypy_integration//repositories:deps.bzl", mypy_integration_deps = "deps")

mypy_integration_deps(
    mypy_requirements_file="//tools/typing:mypy_version.txt",
    # python_interpreter = "python3.9"  # $PATH is searched for exe.
    # OR
    # python_interpreter_target = "@python3_interpreter//:bin/python3",
)
\`\`\`
EOF
