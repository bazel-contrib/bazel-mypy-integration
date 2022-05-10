# WORKSPACE support, to be replaced in the future with bzlmod.
"""
Provides functions to pull the external Mypy package dependency.
"""

load("@rules_python//python:pip.bzl", "pip_install", "package_annotation", "pip_parse")

PY_WHEEL_RULE_CONTENT = """\
load("@aspect_rules_py//py:defs.bzl", "py_wheel")
py_wheel(
    name = "wheel",
    src = ":whl",
)
"""

def mypy_deps(interpreter):
    PACKAGES = ["mypy", "typed-ast"]
    ANNOTATIONS = {
        pkg: package_annotation(additive_build_content = PY_WHEEL_RULE_CONTENT)
        for pkg in PACKAGES
    }

    pip_parse(
        name = "mypy_integration_pip_deps",
        annotations = ANNOTATIONS,
        python_interpreter_target = interpreter,
        requirements_lock = "//:requirements-locked.txt",
    )

# buildifier: disable=function-docstring-args
def py_deps(mypy_requirements_file, python_interpreter, python_interpreter_target, extra_pip_args):
    """Pull in external Python packages needed by py binaries in this repo.

    Pull in all dependencies needed to build the Py binaries in this
    repository. This function assumes the repositories imported by the macro
    'repositories' in //repositories:repositories.bzl have been imported
    already.
    """
    external_repo_name = "mypy_integration_pip_deps"
    excludes = native.existing_rules().keys()
    if external_repo_name not in excludes:
        pip_install(
            name = external_repo_name,
            requirements = mypy_requirements_file,
            python_interpreter = python_interpreter or "python3",  # mypy requires Python3
            python_interpreter_target = python_interpreter_target,
            extra_pip_args = extra_pip_args,
        )
