package(default_visibility = ["//visibility:private"])

licenses(["notice"])  # MIT

exports_files([
    "LICENSE",
    "version.bzl",
    ".mypy.ini",
])

label_flag(
    name = "mypy_config",
    build_setting_default = "//:.mypy.ini",
    visibility = ["//visibility:public"],
)

label_flag(
    name = "mypy",
    # No usable default. Force users to inject mypy.
    build_setting_default = "//tools:empty_library",
    visibility = ["//visibility:public"],
)
