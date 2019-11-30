load("@bazel_skylib//lib:shell.bzl", "shell")

FileCountInfo = provider(
    fields = {
        'count' : 'number of files'
    }
)

def _mypy_aspect_impl(target, ctx):
    print("running mypy aspect")
    count = 0
    # Make sure the rule has a srcs attribute.
    src_files = []
    if hasattr(ctx.rule.attr, 'srcs'):
        # Iterate through the sources counting files
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.path.endswith(".py"):
                    src_files.append(f)
                if ctx.attr.extension == '*':
                    count = count + 1

    # TODO(Jonathon): Remove
    if hasattr(ctx.rule.attr, 'deps'):
        for dep in ctx.rule.attr.deps:
            count = count + dep[FileCountInfo].count

    if not src_files:
        return [
            FileCountInfo(count = count),
        ]

    mypy_exe_path = "/Users/jonathonbelotti/.pyenv/shims/mypy"
    mypy_template_expanded_exe = ctx.actions.declare_file(
        "%s_mypy_exe" % ctx.rule.attr.name
    )
    out = ctx.actions.declare_file("%s_dummy_out" % ctx.rule.attr.name)
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = mypy_template_expanded_exe,
        substitutions = {
            "{MYPY_EXE}": mypy_exe_path,
            "{SRCS}": " ".join([
                shell.quote(f.path) for
                f in src_files
            ]),
            "{OUTPUT}" : out.path
        },
        is_executable = True,
    )

    ctx.actions.run(
        outputs = [out],
        inputs = src_files,
        executable = mypy_template_expanded_exe,
#        arguments = ["{}/{}".format(ctx.label.package, prefix)] + pairs,
        mnemonic = "MyPy",
        use_default_shell_env = True,
    )

    return [
        FileCountInfo(count = count),
        OutputGroupInfo(
            foo = depset([out]),
        )
    ]

mypy_aspect = aspect(implementation = _mypy_aspect_impl,
    attr_aspects = ['deps'],
    attrs = {
        'extension' : attr.string(
            default = "*",
            values = ["*", ".py"]
        ),
        '_template' : attr.label(
            default = Label('@mypy_integration//templates:mypy.sh.tpl'),
            allow_single_file = True,
        ),
    }
)