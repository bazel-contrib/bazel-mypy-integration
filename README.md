<h1 align="center"><code>bazel-mypy-integration</code></h1>
<p align="center">
    <a href="https://github.com/thundergolfer/bazel-mypy-integration/actions/">
        <img src="https://github.com/thundergolfer/bazel-mypy-integration/workflows/CI/badge.svg">
    </a>
</p>
<p align="center">
    <em>Integrate <a href="https://github.com/python/mypy">MyPy</a> type-checking into your Python Bazel builds.</em>
      

---

⚠️ This software is now in 'production' use, but still in the **PRE-RELEASE PHASE** and under active development. Please give it a try, and ⭐️ or watch the repo to follow progress ⚠️

-----

[**`mypy`**](https://github.com/python/mypy) is an incremental type system for Python. Incremental type systems arguably become essential when Python codebases grow to be very large [[1](https://blogs.dropbox.com/tech/2019/09/our-journey-to-type-checking-4-million-lines-of-python/), [2](https://www.facebook.com/notes/protect-the-graph/pyre-fast-type-checking-for-python/2048520695388071/), [3](https://instagram-engineering.com/let-your-code-type-hint-itself-introducing-open-source-monkeytype-a855c7284881), [4](https://github.com/google/pytype)]. As Bazel is a build system designed for very large codebases, it makes sense that they should work together to help a Python codebase scale.

With **`bazel-mypy-integration`**, type errors are flagged as `bazel build` errors, so that teams can be sure their type-checking is being respected. 


## Usage

## Aspect-based

It's recommended that you register this integration's [Aspect](https://docs.bazel.build/versions/master/skylark/aspects.html) to run
everytime you `build` Python code. To do that you can add the following to your `.bazelrc`:

```
build --aspects @mypy_integration//:mypy.bzl%mypy_aspect
build --output_groups=+mypy
```

But if you want to invoke the integration directly, you can do so with:

```
bazel build --aspects @mypy_integration//:mypy.bzl%mypy_aspect --output_groups=mypy  //my/python/code/...
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

### `mypy_test` rule-based

An alternative to registering the Aspect is to use the `mypy_test` rule which will run MyPy when the target run with `bazel test`. 

```
load("@mypy_integration//:mypy.bzl", "mypy_test")

mypy_test(
    name = "foo_mypy_test",
    deps = [
        ":foo", # py_[library, binary, test] target
    ],
)
```

If there's a typing error in your Python code, then the test will fail. Using `--test_output=all` will ensure the MyPy error is visible in the console.

## Installation

**1. Create a file that will specify the version of `mypy` to use.** You will pass the Bazel label for
this file to the `deps()` function in `@mypy_integration//repositories:deps.bzl`, which below is named
`mypy_integration_deps(...)`:

```
mypy==0.790
``` 

❣️ Ensure that your selected MyPy version is compatible with your Python version. Incompatibilities can produce [obscure looking errors](https://github.com/thundergolfer/bazel-mypy-integration/issues/38).

(In the [`examples/`](examples/) Bazel workspace this file is specified in [`tools/typing/`](examples/tools/typing))

**2. Next, add the following to your `WORKSPACE`:**

```python
mypy_integration_version = "0.2.1"  # latest @ September 28th 2021

http_archive(
    name = "mypy_integration",
    sha256 = "e9701c43bdf4082b1719d91954b7838c85021e086a26e1b7c8adbe6fbff3c7ef",
    url = "https://github.com/thundergolfer/bazel-mypy-integration/releases/download/{version}/bazel_mypy_integration-{version}.tar.gz".format(
        version = mypy_integration_version,
    ),
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
```

_Note_ that by default `mypy_integration_deps` will default to passing `"python3"` as the interpreter used at install,
but this can be overridden by setting `python_interpreter` or `python_interpreter_target` (but not both).

**3. Finally, if using the Bazel Aspect, add the following to your `.bazelrc` so that MyPy checking is run whenever
Python code is built:**

```
build --aspects @mypy_integration//:mypy.bzl%mypy_aspect
build --output_groups=+mypy
```

**3b. If using the Bazel rule, you'll add to a `BUILD` file something like:**

```python
load("@mypy_integration//:mypy.bzl", "mypy_test")

py_binary(
    name = "foo",
    srcs = glob(["foopy"]),
    main = "foo.py",
    python_version = "PY3",
    deps = [],
)

mypy_test(
    name = "foo_mypy",
    deps = [
        ":foo",
    ],
)
```

### Configuration

To support the [MyPy configuration file](https://mypy.readthedocs.io/en/latest/config_file.html) you can add the
following to your `WORKSPACE`:

```
load("@mypy_integration//:config.bzl", "mypy_configuration")

mypy_configuration("//tools/typing:mypy.ini")
```

where `//tools/typing:mypy.ini` is a [valid MyPy config file](https://mypy.readthedocs.io/en/latest/config_file.html#config-file-format).


## 🛠 Development

### Testing 

`./test.sh` runs some basic integration tests. Right now, running the integration in the
Bazel workspace in `examples/` tests a lot more functionality but can't automatically
test failure cases.
