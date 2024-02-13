## `examples/` Bazel Workspace

This workspace contains various folders that demonstrate working functionality
of this Bazel integration. It was relied on heavily in this project's early development
phase to check things were working.

You can run the integration over the whole workspace by running:

```
bazel build \
    --aspects @mypy_integration//:mypy.bzl%mypy_aspect \
     --output_groups=mypy //...
```

This workspace defines its **MyPy version** in [`//tools/typing:mypy_requirements.txt`](./tools/typing/mypy_requirements.txt)
and its **MyPy config** in [`//tools/typing:mypy.ini`](./tools/typing/mypy.ini).
