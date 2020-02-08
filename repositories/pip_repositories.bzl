# Once recursive workspace is implemented in Bazel, this file should cease
# to exist.
"""
Provides functions to pull all Python external package dependencies of this
repository.
"""

load("@mypy_integration_pip_deps//:requirements.bzl", "pip_install")

def pip_deps():
    """Pull in external pip packages needed by py binaries in this repo.
    Pull in all pip dependencies needed to build the Py binaries in this
    repository. This function assumes the repositories imported by the macros
    'repositories' in //repositories:repositories.bzl and 'py_deps' in
    //repositories:py_repositories.bzl have been imported
    already.
    """
    pip_install()
