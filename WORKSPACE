workspace(name = "bazel_mypy_integration")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "//repositories:repositories.bzl",
    mypy_integration_repositories = "repositories",
)

mypy_integration_repositories()

load("//:config.bzl", "mypy_configuration")

mypy_configuration()

load("@rules_python//python:repositories.bzl", "python_register_toolchains")

python_register_toolchains(
    name = "python3_8",
    python_version = "3.8",
)

load("@python3_8//:defs.bzl", "interpreter")

load("//repositories:deps.bzl", mypy_integration_deps = "deps")

mypy_integration_deps(
    "//:current_mypy_version.txt",
    python_interpreter = interpreter,
)

http_archive(
    name = "buildifier_prebuilt",
    sha256 = "0450069a99db3d414eff738dd8ad4c0969928af13dc8614adbd1c603a835caad",
    strip_prefix = "buildifier-prebuilt-0.4.0",
    urls = [
        "http://github.com/keith/buildifier-prebuilt/archive/0.4.0.tar.gz",
    ],
)

load("@buildifier_prebuilt//:deps.bzl", "buildifier_prebuilt_deps")

buildifier_prebuilt_deps()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")

buildifier_prebuilt_register_toolchains()

http_archive(
    name = "com_google_protobuf",
    sha256 = "14e8042b5da37652c92ef6a2759e7d2979d295f60afd7767825e3de68c856c54",
    strip_prefix = "protobuf-3.18.0",
    urls = [
        "https://mirror.bazel.build/github.com/protocolbuffers/protobuf/archive/v3.18.0.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/v3.18.0.tar.gz",
    ],
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

http_archive(
    name = "com_github_bazelbuild_buildtools",
    strip_prefix = "buildtools-master",
    url = "https://github.com/bazelbuild/buildtools/archive/master.zip",
)

load("@aspect_rules_py//py:repositories.bzl", "rules_py_dependencies")

rules_py_dependencies()

load("@mypy_integration_pip_deps//:requirements.bzl", "install_deps")

install_deps()