# `bazel-mypy-integration`

_Integrate [MyPy](https://github.com/python/mypy) type-checking into your Python Bazel builds._

-----

[**`mypy`**](https://github.com/python/mypy) is an incremental type system for Python. Incremental type systems arguably become essential when Python codebases grow to be very large [[1](https://blogs.dropbox.com/tech/2019/09/our-journey-to-type-checking-4-million-lines-of-python/), [2](https://www.facebook.com/notes/protect-the-graph/pyre-fast-type-checking-for-python/2048520695388071/), [3](https://instagram-engineering.com/let-your-code-type-hint-itself-introducing-open-source-monkeytype-a855c7284881), [4](https://github.com/google/pytype)]. As Bazel is a build system designed for very large codebases, it makes sense that they should work together to help a Python codebase scale.

With **`bazel-mypy-integration`**, type errors are flagged as `bazel build` errors, so that teams can be sure their type-checking is being respected. 


## Usage

```
coming soon...
```

## Installation

Create a file that will specify the version of `mypy` to use. You will pass the Bazel label for
this file to the `deps()` function in `@mypy_integration//repositories:deps.bzl`, which below is named
`mypy_integration_deps(...)`:

```
mypy==0.750
```

(In the [`examples/`](examples/) Bazel workspace this file is specified in [`tools/typing/`](examples/tools/typing))

Next, add the following to your `WORKSPACE`:

```python
mypy_integration_version = "XXX"

http_archive(
    name = "mypy_integration",
    # sha256 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    strip_prefix = "bazel-linting-system-{version}".format(version = mypy_integration_version),
    url = "https://github.com/thundergolfer/bazel-mypy-integration/archive/v{version}.zip".format(
        version = mypy_integration_version
    ),
)

load(
    "@mypy_integration//repositories:repositories.bzl",
    mypy_integration_repositories = "repositories",
)
mypy_integration_repositories()

load("@mypy_integration//repositories:deps.bzl", mypy_integration_deps = "deps")

mypy_integration_deps("//tools/typing:mypy_version.txt")

load("@mypy_integration//repositories:pip_repositories.bzl", "pip_deps")

pip_deps()
```

Finally, add the following to your `.bazelrc` so that MyPy checking is run whenever
Python code is built:

```
build --aspects @mypy_integration//:mypy.bzl%mypy_aspect
build --output_groups=+foo
```
