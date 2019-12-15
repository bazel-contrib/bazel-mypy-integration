# `bazel-mypy-integration`

_Integrate [MyPy](https://github.com/python/mypy) type-checking into your Python Bazel builds._

-----

⚠️ This software is in **PRE-ALPHA PHASE** and under active development. ⭐️ or watch the repo to follow progress ⚠️

-----

[**`mypy`**](https://github.com/python/mypy) is an incremental type system for Python. Incremental type systems arguably become essential when Python codebases grow to be very large [[1](https://blogs.dropbox.com/tech/2019/09/our-journey-to-type-checking-4-million-lines-of-python/), [2](https://www.facebook.com/notes/protect-the-graph/pyre-fast-type-checking-for-python/2048520695388071/), [3](https://instagram-engineering.com/let-your-code-type-hint-itself-introducing-open-source-monkeytype-a855c7284881), [4](https://github.com/google/pytype)]. As Bazel is a build system designed for very large codebases, it makes sense that they should work together to help a Python codebase scale.

With **`bazel-mypy-integration`**, type errors are flagged as `bazel build` errors, so that teams can be sure their type-checking is being respected. 


## Usage

It's highly recommended that you register this integration's [Aspect](https://docs.bazel.build/versions/master/skylark/aspects.html) to run
everytime you `build` Python code. To do that you can add the following to your `.bazelrc`:

```
build --aspects @mypy_integration//:mypy.bzl%mypy_aspect
build --output_groups=+foo
```

But if you want to invoke the integration directly, you can do so with:

```
bazel build --aspects @mypy_integration//:mypy.bzl%mypy_aspect --output_groups=foo  //my/python/code/...
```

If there's a typing error in your Python code, then your `build` will fail. You'll see something like:

```bash
ERROR: /Users/jonathonbelotti/Code/thundergolfer/bazel-mypy-integration/examples/hangman/BUILD:1:1: 
MyPy hangman/hangman_dummy_out failed (Exit 1) hangman_mypy_exe failed: error executing command bazel-out/darwin-fastbuild/bin/hangman/hangman_mypy_exe

Use --sandbox_debug to see verbose messages from the sandbox
hangman/hangman.py:52: error: Syntax error in type annotation
hangman/hangman.py:52: note: Suggestion: Use Tuple[T1, ..., Tn] instead of (T1, ..., Tn)
Found 1 error in 1 file (checked 1 source file)
INFO: Elapsed time: 2.026s, Critical Path: 1.85s
INFO: 1 process: 1 darwin-sandbox.
FAILED: Build did NOT complete successfully
```

## Installation

**1. Create a file that will specify the version of `mypy` to use.** You will pass the Bazel label for
this file to the `deps()` function in `@mypy_integration//repositories:deps.bzl`, which below is named
`mypy_integration_deps(...)`:

```
mypy==0.750
```

⚠️ _Note: Currently only `0.750` (latest) is being supported, but the idea is to support multiple versions in future using the above mechanism._ 

(In the [`examples/`](examples/) Bazel workspace this file is specified in [`tools/typing/`](examples/tools/typing))

**2. Next, add the following to your `WORKSPACE`:**

```python
mypy_integration_version = "0.0.1" # latest @ Dec 1st 2019

http_archive(
    name = "mypy_integration",
    sha256 = "00ec35a947d6554de01e1af137a5f5708f210f24404054b8ddb7b80ec9f04e17", # for 0.0.1
    strip_prefix = "bazel-linting-system-{version}".format(version = mypy_integration_version),
    url = "https://github.com/thundergolfer/bazel-mypy-integration/archive/{version}.zip".format(
        version = mypy_integration_version
    ),
)

load(
    "@mypy_integration//repositories:repositories.bzl",
    mypy_integration_repositories = "repositories",
)
mypy_integration_repositories()

# Optionally pass a MyPy config file.
load("@mypy_integration//:config.bzl", "mypy_configuration")
mypy_configuration("//tools/typing:mypy.ini")

load("@mypy_integration//repositories:deps.bzl", mypy_integration_deps = "deps")

mypy_integration_deps("//tools/typing:mypy_version.txt")

load("@mypy_integration//repositories:pip_repositories.bzl", "pip_deps")

pip_deps()
```

**3. Finally, add the following to your `.bazelrc` so that MyPy checking is run whenever
Python code is built:**

```
build --aspects @mypy_integration//:mypy.bzl%mypy_aspect
build --output_groups=+foo
```

### Configuration

To support the [MyPy configuration file](https://mypy.readthedocs.io/en/latest/config_file.html) you can add the
following to your `WORKSPACE`:

```
load("@mypy_integration//:config.bzl", "mypy_configuration")

mypy_configuration("//tools/typing:mypy.ini")
```

where `//tools/typing:mypy.ini` is a [valid MyPy config file](https://mypy.readthedocs.io/en/latest/config_file.html#config-file-format).
