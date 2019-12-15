workspace(name = "bazel_mypy_integration")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load(
    "//repositories:repositories.bzl",
    mypy_integration_repositories = "repositories",
)
mypy_integration_repositories()

load("//:config.bzl", "mypy_configuration")

mypy_configuration()

load("//repositories:deps.bzl", mypy_integration_deps = "deps")

mypy_integration_deps("//:current_mypy_version.txt")

load("//repositories:pip_repositories.bzl", "pip_deps")

pip_deps()

########################
# PYTHON SUPPORT
########################
rules_python_version = "7b222cfdb4e59b9fd2a609e1fbb233e94fdcde7c"

http_archive(
    name = "rules_python",
    sha256 = "d2865e2ce23ee217aaa408ddaa024ca472114a6f250b46159d27de05530c75e3",
    strip_prefix = "rules_python-{version}".format(version = rules_python_version),
    url = "https://github.com/bazelbuild/rules_python/archive/{version}.tar.gz".format(version = rules_python_version),
)

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

# Only needed if using the packaging rules.
load("@rules_python//python:pip.bzl", "pip_repositories")
pip_repositories()

load("@rules_python//python:pip.bzl", "pip_import")

pip_import(   # or pip3_import
   name = "my_deps",
   requirements = "//third_party:requirements.txt",
   python_interpreter = "python3",
)

load("@my_deps//:requirements.bzl", "pip_install")
pip_install()
