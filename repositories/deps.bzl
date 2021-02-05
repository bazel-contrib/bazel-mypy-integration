# NOTE: Once recursive workspaces are implemented in Bazel, this file should cease to exist.
"""
Provides functions to pull all external package dependencies of this
repository.
"""

load(":py_repositories.bzl", "py_deps")

def deps(mypy_requirements_file, python_interpreter=None, python_interpreter_target=None):
    """Pull in external dependencies needed by rules in this repo.
    Pull in all dependencies needed to run rules in this
    repository.

    ❗️ This function assumes the repositories imported by the macro
    'repositories' in //repositories:repositories.bzl have been imported
    already.
    """
    py_deps(mypy_requirements_file, python_interpreter, python_interpreter_target)
