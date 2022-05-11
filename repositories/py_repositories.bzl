# NOTE: Once recursive workspaces are implemented in Bazel, this file should cease to exist.
"""
Provides functions to pull the external Mypy package dependency.
"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_python//python:pip.bzl", _pip_install = "pip_install")

def pip_install(name, **kwargs):
    maybe(_pip_install, name = name, **kwargs)

# buildifier: disable=function-docstring-args
def py_deps(mypy_requirements_file, python_interpreter, python_interpreter_target, extra_pip_args):
    """Pull in external Python packages needed by py binaries in this repo.

    Pull in all dependencies needed to build the Py binaries in this
    repository. This function assumes the repositories imported by the macro
    'repositories' in //repositories:repositories.bzl have been imported
    already.
    """
    external_repo_name = "mypy_integration_pip_deps"
    
    pip_install(
        name = external_repo_name,
        requirements = mypy_requirements_file,
        python_interpreter = python_interpreter or "python3",  # mypy requires Python3
        python_interpreter_target = python_interpreter_target,
        extra_pip_args = extra_pip_args,
    )
