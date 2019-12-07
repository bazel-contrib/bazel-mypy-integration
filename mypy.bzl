load("@bazel_skylib//lib:shell.bzl", "shell")

DEBUG = True

def _sources_to_cache_map_triples(srcs):
    triples_as_flat_list = []
    for f in srcs:
        triples_as_flat_list.extend([
            shell.quote(f.path),
            shell.quote("{}.meta.json".format(f.path)),
            shell.quote("{}.data.json".format(f.path))
        ])
    return triples_as_flat_list

def _mypy_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library", "py_test"]:
        return []

    # Make sure the rule has a srcs attribute.
    src_files = []
    if hasattr(ctx.rule.attr, 'srcs'):
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.path.endswith(".py"):
                    src_files.append(f)

    # TODO(Jonathon): Need to include deps in MyPy call for type-checking
    if hasattr(ctx.rule.attr, 'deps'):
        for dep in ctx.rule.attr.deps:
            pass

    if not src_files:
        return []

    mypy_template_expanded_exe = ctx.actions.declare_file(
        "%s_mypy_exe" % ctx.rule.attr.name
    )
    out = ctx.actions.declare_file("%s_dummy_out" % ctx.rule.attr.name)
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = mypy_template_expanded_exe,
        substitutions = {
            "{MYPY_EXE}": ctx.executable._mypy_cli.path,
            "{CACHE_MAP_TRIPLES}": " ".join(_sources_to_cache_map_triples(src_files)),
            "{SRCS}": " ".join([
                shell.quote(f.path) for
                f in src_files
            ]),
            "{VERBOSE_OPT}": "--verbose" if DEBUG else "",
            "{OUTPUT}" : out.path,
        },
        is_executable = True,
    )

    ctx.actions.run(
        outputs = [out],
        inputs = src_files,
        tools = [ctx.executable._mypy_cli],
        executable = mypy_template_expanded_exe,
#        arguments = ["{}/{}".format(ctx.label.package, prefix)] + pairs,
        mnemonic = "MyPy",
        use_default_shell_env = True,
    )

    return [
        OutputGroupInfo(
            foo = depset([out]),
        )
    ]

mypy_aspect = aspect(implementation = _mypy_aspect_impl,
    attr_aspects = ['deps'],
    attrs = {
        # TODO(Jonathon): Remove this, it's vestigial
        "extension" : attr.string(
            default = "*",
            values = ["*", ".py"]
        ),
        "_template" : attr.label(
            default = Label("@mypy_integration//templates:mypy.sh.tpl"),
            allow_single_file = True,
        ),
        "_mypy_cli": attr.label(
            default = Label("@mypy_integration//mypy"),
            executable = True,
            cfg = "host",
        )

    }
)