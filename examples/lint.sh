#!/usr/bin/env bash

bazel build //... \
    --aspects //tools/linting:aspect.bzl%lint \
    --output_groups=report

bazel run @linting_system//:apply_changes -- \
  "$(git rev-parse --show-toplevel)/examples" \
  "$(bazel info bazel-genfiles)" \
  "$(bazel query //... | tr '\n' ' ')"
