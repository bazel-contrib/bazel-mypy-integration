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

It's recommended that you register this integration's [Aspect](https://bazel.build/rules/aspects) to run
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

`mypy_integration` expects the user to provide the `mypy` dependency.
Given not every mypy version is compatible to all Python versions and mypy's transitive dependencies can differ based on the Python version `mypy_integration` cannot offer a `mypy` which satisfies all potential users.

**1. Provide `mypy` to `mypy_integration`. You can do so in 2 ways**:
  - Add to your Bazel command `--@mypy_integration//:mypy=<your_target_providing_mypy>`
  - Add to your bazelrc `build --@mypy_integration//:mypy=<your_target_providing_mypy>`

❣️ Ensure that your selected MyPy version is compatible with your Python version. Incompatibilities can produce [obscure looking errors](https://github.com/thundergolfer/bazel-mypy-integration/issues/38).

**2. Finally, if using the Bazel Aspect, add the following to your `.bazelrc` so that MyPy checking is run whenever
Python code is built:**

```
build --aspects @mypy_integration//:mypy.bzl%mypy_aspect
build --output_groups=+mypy
```

**2b. If using the Bazel rule, you'll add to a `BUILD` file something like:**

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
following to your `.bazelrc`:

```text
build --@mypy_integration//:mypy_config=//:mypy.ini
```

where `//:mypy.ini` is a [valid MyPy config file](https://mypy.readthedocs.io/en/latest/config_file.html#config-file-format)
within your projects workspace.

## 🛠 Development

### Testing 

`./test.sh` runs some basic integration tests. Right now, running the integration in the
Bazel workspace in `examples/` tests a lot more functionality but can't automatically
test failure cases.
