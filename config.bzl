"""
Provides functions to support (optionally) passing the MyPy configuration file
to this integration.
"""


def _create_config_impl(ctx):
    print(ctx.attr.config_filepath)
    print("this is from create config impl")
    ctx.file(
        "mypy.ini",
        content='FUCK',
        executable=False
    )

create_config = repository_rule(
    implementation=_create_config_impl,
    attrs = {
        "config_filepath": attr.label(
            mandatory = False,
            allow_single_file = True,
            doc = "The path to the mypy.ini, if one is used..",
        ),
    }
)

def mypy_configuration(mypy_config_file=None):
    create_config(
        name = "mypy_config",
        config_filepath=mypy_config_file,
    )
