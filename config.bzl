"""
Provides functions to support (optionally) passing the MyPy configuration file
to this integration.
"""

def _create_config_impl(rctx):
    if rctx.attr.config_filepath:
        user_mypy_config_contents = rctx.read(rctx.attr.config_filepath)
    else:
        user_mypy_config_contents = "[mypy]"

    rctx.file(
        "mypy.ini",
        content = user_mypy_config_contents,
        executable = False,
    )
    rctx.file(
        "BUILD",
        content = "exports_files(['mypy.ini'])",
        executable = False,
    )

create_config = repository_rule(
    implementation = _create_config_impl,
    attrs = {
        "config_filepath": attr.label(
            mandatory = False,
            allow_single_file = True,
            doc = "The path to the mypy.ini, if one is used..",
        ),
    },
)

def mypy_configuration(mypy_config_file = None):
    """**Deprecated**: Instead, see https://github.com/bazel-contrib/bazel-mypy-integration/blob/main/README.md#configuration

    Args:
        mypy_config_file (Label, optional): The label of a mypy configuration file
    """
    create_config(
        name = "mypy_integration_config",
        config_filepath = mypy_config_file,
    )
