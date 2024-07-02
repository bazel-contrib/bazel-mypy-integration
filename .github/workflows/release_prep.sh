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
## Using Bzlmod (Recommended for Bazel 6 or later)

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "mypy_integration", version = "${TAG:1}")
\`\`\`

## Using WORKSPACE (Legacy)

Add to your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "mypy_integration",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/bazel-contrib/bazel-mypy-integration/releases/download/${TAG}/${ARCHIVE}",
)

load("@mypy_integration//repositories:repositories.bzl", mypy_integration_repositories = "repositories")

mypy_integration_repositories()
\`\`\`
EOF
