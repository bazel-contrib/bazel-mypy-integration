"""
Provides functions to support (optionally) passing the MyPy configuration file
to this integration.
"""

def _create_config_impl(ctx):
    if ctx.attr.config_filepath:
        user_mypy_config_contents = ctx.read(ctx.attr.config_filepath)
    else:
        user_mypy_config_contents = "[mypy]"

    ctx.file(
        "mypy.ini",
        content = user_mypy_config_contents,
        executable = False,
    )
    ctx.file(
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
    create_config(
        name = "mypy_integration_config",
        config_filepath = mypy_config_file,
    )
