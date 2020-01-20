load("@bazel_skylib//lib:shell.bzl", "shell")
load("//:rules.bzl", "MyPyStubsInfo")

# Switch to True only during debugging and development.
# All releases should have this as False.
DEBUG = False

VALID_EXTENSIONS = ["py", "pyi"]

def _sources_to_cache_map_triples(srcs):
    triples_as_flat_list = []
    for f in srcs:
        triples_as_flat_list.extend([
            shell.quote(f.path),
            shell.quote("{}.meta.json".format(f.path)),
            shell.quote("{}.data.json".format(f.path))
        ])
    return triples_as_flat_list

def _is_external_dep(dep):
    return dep.label.workspace_root.startswith("external/")

def _is_external_src(src_file):
    return src_file.path.startswith("external/")

def _mypy_aspect_impl(target, ctx):
    if ctx.rule.kind not in ["py_binary", "py_library", "py_test"]:
        return []

    mypy_config_file = ctx.file._mypy_config

    # Make sure the rule has a srcs attribute.
    direct_src_files = []
    if hasattr(ctx.rule.attr, 'srcs'):
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.extension in VALID_EXTENSIONS:
                    direct_src_files.append(f)

    direct_src_files_depset = depset(direct=direct_src_files)
    mypypath = None

    stub_files = []
    transitive_srcs_depsets = []
    if hasattr(ctx.rule.attr, 'deps'):
        # Need to add the .py files AND the .pyi files that are
        # deps of the rule
        for dep in ctx.rule.attr.deps:
            if MyPyStubsInfo in dep:
                for stub_srcs_target in dep[MyPyStubsInfo].srcs:
                    for src_f in stub_srcs_target.files.to_list():
                        if src_f.extension == "pyi":
                            mypypath = src_f.dirname
                            stub_files.append(src_f)
            elif PyInfo in dep and not _is_external_dep(dep):
                transitive_srcs_depsets.append(dep[PyInfo].transitive_sources)

    final_srcs_depset = depset(transitive = transitive_srcs_depsets + [direct_src_files_depset])
    src_files = [f for f in final_srcs_depset.to_list() if not _is_external_src(f)]
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
            "{OUTPUT}": out.path,
            "{MYPYPATH_PATH}": mypypath if mypypath else "",
            "{MYPY_INI_PATH}": mypy_config_file.path
        },
        is_executable = True,
    )

    ctx.actions.run(
        outputs = [out],
        inputs = src_files + stub_files + [mypy_config_file],
        tools = [ctx.executable._mypy_cli],
        executable = mypy_template_expanded_exe,
        mnemonic = "MyPy",
        use_default_shell_env = True,
    )

    return [
        OutputGroupInfo(
            mypy = depset([out]),
        )
    ]

mypy_aspect = aspect(implementation = _mypy_aspect_impl,
    attr_aspects = ['deps'],
    attrs = {
        "_template" : attr.label(
            default = Label("//templates:mypy.sh.tpl"),
            allow_single_file = True,
        ),
        "_mypy_cli": attr.label(
            default = Label("//mypy"),
            executable = True,
            cfg = "host",
        ),
        "_mypy_config": attr.label(
            default = Label("@mypy_integration_config//:mypy.ini"),
            allow_single_file = True,
        ),
    }
)
