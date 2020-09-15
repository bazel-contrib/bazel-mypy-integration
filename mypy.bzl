load("@mypy_integration_pip_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:sets.bzl", "sets")
load("//:rules.bzl", "MyPyStubsInfo")

MyPyAspectInfo = provider(
    fields = {
        "exe": "Used to pass the rule implementation built exe back to calling aspect.",
        "out": "Used to pass the dummy output file back to calling aspect.",
        "direct_imports": """\
This is a set of import paths, similar to PyInfo.imports. But since PyInfo.imports is transitive,
this provides only the the set of imports used by the exact depset of targets.

NOTE: This is only needed by the mypy_test rule, because it needs to find the direct import paths of
all of its .deps.""",
        "direct_metadata_files": """\
Used to return the set of metadata files produced by a single rule. This is only used to propagate a
return value through a macro.
""",
        "metadata_files": """\
Depset of direct and transitive mypy metadata files (.meta.json and .data.json files). Propagated to
all mypy-using dependants of a py_* target.

This is slightly redundant, considering this information is also in metadata_triples.  However,
digging up the File dependencies from metadata_tripleswould involve flattening and inspecting the
depset, which is costly. Instead, this bit of redundant information contains *just* the metadata
Files we're intresting in.
""",
        "metadata_triples": """\
Depset of structs to propagate the --cache-map values of a given .py[i] source file and its
generated .meta.json and .data.json files.

These 3 values must be kept together, since they are using to construct --cache-map argument
triples, in the form of '--cache-map path/source.py cache/source.meta.json cache/source.data.json'.
""",
    },
)

MyPyStdLibCacheInfo = provider(
    doc = """\
This is a provider strictly for the typeshed std lib cache information, which is given its own
fields to keep it somewhat distinct from MyPyAspectInfo.
""",
    fields = {
        "stdlib_stub_files": """\
depset of Files. Used to provide the set of .pyi stub files provided by typeshed (a baked-in
dependency of mypy).
""",
        "stdlib_stub_anchor": """\
Used to provide a File which is a member of the typeshed stdlib set. Any such File will do. This is
used only to make getting the typeshed directory work in a general way, without fixing a f.path in
the provider.

We need a general mechanism for this because the typeshed directory passed to mypy may be a
.short_path, in the case of pointing inside a runfiles.

This field is always one of the stdlib_stub_files list.
""",
    },
)

_MyPyCacheTripleInfo = provider(
    doc = """\
Provider for mypy cache map arguments. mypy's --cache-map argument format is:

<the py file> <the destination for .meta.json> <the destination for .data.json>

This is an implementation detail, not to be used outside this file.
        """,
    fields = [
        "py",  # A File.
        "meta",  # A File.
        "data",  # A File.
    ],
)

# Switch to True only during debugging and development.
# All releases should have this as False.
DEBUG = False

VALID_EXTENSIONS = ["py", "pyi"]

CACHE_SUBDIR = "_mypy_cache"

DEFAULT_ATTRS = {
    "_template": attr.label(
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

STDLIB_CACHED_METADATA_ATTRS = {
    "_stdlib_cached_metadata": attr.label(
        doc = """
The singleton mypy_stdlib_cache_library target. This is used to generate and propagate the mypy
cacheable metadata for the typeshed stdlib stubs.
""",
        default = Label("//mypy:mypy_stdlib_cache"),
    ),
}

def _get_stdlib_typeshed_dir_from_path(path):
    """Find the `typeshed` directory from a path.

    Typeshed is a baked-in dependency of mypy.

    Args:
      path: The given path must be a string representing a path that contains "/typeshed/stdlib".

    Returns:
      The return value is a string pointing to everything in `path` up to and including `/typeshed`
    """
    if "/typeshed/stdlib" not in path:
        fail("{} is not a path to a file under the typeshed/stdlib directory".format(path))
    typeshed_stdlib_dir, _ = path.split("/typeshed/stdlib")
    return paths.join(typeshed_stdlib_dir, "typeshed")

def _triple_to_list_of_paths(triple):
    """Expand the triple into the list of strings expected on the command line.

    This is used in map_each.

    Args:
      triple: a struct, with the structure in _MyPyCacheTripleInfo.

    Returns:
      A list of 3 paths, representing the args to be passed to mypy's --cache-map.
    """
    return [
        triple.py.path,
        triple.meta.path,
        triple.data.path,
    ]

def _triple_to_list_of_shortpaths(triple):
    """Same as _triple_to_list_of_paths, but with .short_path."""
    return [
        triple.py.short_path,
        triple.meta.short_path,
        triple.data.short_path,
    ]

def _sources_to_cache_map_triples(ctx, srcs):
    """Given a list of sources (Files), return metadata filenames for them.

    Args:
      ctx: The rule context.
      srcs: list of File objects, representing python sources/stubs.

    Returns:
      List of structs, where each struct has:
        py: the source file (File)
        meta_filename: string, filename of the meta.json file for the given source file. This is not a declared file.
        data_filename: string, filename of the data.json file for the given source file. This is not a declared file.
    """
    package = ctx.label.package
    workspace_root = ctx.label.workspace_root

    triples_as_flat_list = []
    for f in srcs:
        meta = paths.join(
            CACHE_SUBDIR,
            "{}_{}.meta.json".format(ctx.label.name, f.basename),
        )
        data = paths.join(
            CACHE_SUBDIR,
            "{}_{}.data.json".format(ctx.label.name, f.basename),
        )
        triples_as_flat_list.append(
            # This is not a _MyPyCacheTripleInfo, because the metadata components are not Files but
            # just string filenames.
            struct(
                py = f,
                meta_filename = meta,
                data_filename = data,
            ),
        )
    return triples_as_flat_list

def _is_external_dep(dep):
    return dep.label.workspace_root.startswith("external/")

def _is_external_src(src_file):
    return src_file.path.startswith("external/")

def _is_typeshed_src(src_file):
    # TODO: Do these need to be set independently somewhere? Even under 3.6, all the typeshed files
    # in 3.6+ are able to be mypy parsed and cached just fine, so there are no fundamental issues
    # with including them all.
    typeshed_for_3_6 = True
    typeshed_for_3_7 = True
    typeshed_for_3_8 = True
    typeshed_for_3_9 = True

    # typing_extensions is always required:
    if "mypy/typeshed/third_party/2and3/typing_extensions" in src_file.path:
        return True

    # Python 2.x stubs that are identical to their python3.x stubs are located here:
    if "mypy/typeshed/stdlib/2and3/" in src_file.path:
        return True

    # Python 3.x stubs are all located here. Note: trailing slash is necessary!
    if "mypy/typeshed/stdlib/3/" in src_file.path:
        return True

    # Note: This is python 3.6 specific. Update as necessary:
    if typeshed_for_3_6 and "mypy/typeshed/stdlib/3.6" in src_file.path:
        return True
    if typeshed_for_3_7 and "mypy/typeshed/stdlib/3.7" in src_file.path:
        return True
    if typeshed_for_3_8 and "mypy/typeshed/stdlib/3.8" in src_file.path:
        return True
    if typeshed_for_3_9 and "mypy/typeshed/stdlib/3.9" in src_file.path:
        return True
    return False

def _extract_srcs(srcs):
    direct_src_files = []
    for src in srcs:
        for f in src.files.to_list():
            if f.extension in VALID_EXTENSIONS:
                direct_src_files.append(f)
    return direct_src_files

def _extract_transitive_deps(deps):
    transitive_deps = []
    for dep in deps:
        if MyPyStubsInfo not in dep and PyInfo in dep and not _is_external_dep(dep):
            transitive_deps.append(dep[PyInfo].transitive_sources)
    return transitive_deps

def _extract_stub_deps(deps):
    # Need to add the .py files AND the .pyi files that are
    # deps of the rule
    stub_files = []
    for dep in deps:
        if MyPyStubsInfo in dep:
            for stub_srcs_target in dep[MyPyStubsInfo].srcs:
                for src_f in stub_srcs_target.files.to_list():
                    if src_f.extension == "pyi":
                        stub_files.append(src_f)
    return stub_files

def _extract_imports(imports, label):
    # NOTE: Bazel's implementation of this for py_binary, py_test is at
    # src/main/java/com/google/devtools/build/lib/bazel/rules/python/BazelPythonSemantics.java
    mypypath_parts = []
    for import_ in imports:
        if import_.startswith("/"):
            print("ignoring invalid absolute path '{}'".format(import_))
        elif import_ in ["", "."]:
            mypypath_parts.append(label.package)
        else:
            mypypath_parts.append("{}/{}".format(label.package, import_))
    return mypypath_parts

def _extract_first_order_dep_srcs(deps):
    first_order_dep_srcs = []
    for dep in deps:
        if MyPyStubsInfo not in dep and PyInfo in dep and not _is_external_dep(dep):
            # Compare with _extract_transitive_deps(), which uses .transitive_sources.
            for f in dep.files.to_list():
                if f.extension in VALID_EXTENSIONS:
                    first_order_dep_srcs.append(f)

    return first_order_dep_srcs

def _extract_transitive_imports(ctx, deps):
    transitive_import_paths = []
    for dep in deps:
        if MyPyStubsInfo not in dep and PyInfo in dep and not _is_external_dep(dep):
            # For some reason, the import paths provided in the PyInfo provider are relative to the
            # top-level execroot folder, which is not very useful to us as ctx.actions.run() will
            # always execute from within the workspace folder.
            transitive_import_paths.extend(
                [
                    paths.relativize(p, ctx.workspace_name) if p.startswith(ctx.workspace_name) else paths.join("external", p)
                    for p in dep[PyInfo].imports.to_list()
                ],
            )

    return transitive_import_paths

def _extract_first_order_imports(deps):
    first_order_dep_imports = []
    for dep in deps:
        if MyPyStubsInfo not in dep and MyPyAspectInfo in dep and not _is_external_dep(dep):
            first_order_dep_imports.extend(dep[MyPyAspectInfo].direct_imports)
    return first_order_dep_imports

def _extract_transitive_metadata_triples(ctx, deps):
    transitive_metadata_triples = []
    for dep in deps:
        if MyPyAspectInfo in dep:
            aspect_info = dep[MyPyAspectInfo]
            transitive_metadata_triples.append(aspect_info.metadata_triples)
    return transitive_metadata_triples

def _extract_transitive_metadata_files(ctx, deps):
    transitive_metadata_files = []
    for dep in deps:
        if MyPyAspectInfo in dep:
            aspect_info = dep[MyPyAspectInfo]
            transitive_metadata_files.append(aspect_info.metadata_files)
    return transitive_metadata_files

def _short_path_getter(file_):
    """Given a File, return the .short_path"""
    return file_.short_path

def _path_getter(file_):
    """Given a File, return the .path"""
    return file_.path

def path_to_py_module(path):
    """Convert a path (string) of a .py file to its module path.

    """
    path_no_ext, ext = paths.split_extension(path)
    if ext != ".py":
        fail("{} does not end with .py".format(path))

    parts = path_no_ext.split("/")

    # Remove __init__.py from the path components. The parent directory of __init__.py is the
    # module.
    if parts[-1] == "__init__":
        parts.pop(-1)

    return ".".join(parts)

def _direct_srcs_to_modules(direct_imports, direct_src_files):
    if not direct_imports:
        # There are no import paths, so assume the files live directly under ".".
        direct_imports = ["."]

    rel_srcs = []
    for src in direct_src_files:
        # TODO: Document this: don't know how to handle multiple direct_import paths, and it's
        # kind of a shit pattern.
        import_path = direct_imports[0]

        rel_srcs.append(paths.normalize(paths.relativize(src.short_path, import_path)))

    ret = [path_to_py_module(p) for p in rel_srcs]
    return ret

def _mypy_rule_impl(ctx, is_aspect = False):
    # This impl is used by tests and aspects rules.
    is_test = not is_aspect

    base_rule = ctx
    if is_aspect:
        base_rule = ctx.rule

    # This impl is used by both the aspect and the test rules defined below. As such, it needs to be
    # aware of looking for files inside of a runfiles (for a test) or not (for aspects).
    if is_test:
        path_helper = _short_path_getter
    else:
        path_helper = _path_getter

    mypy_config_file = ctx.file._mypy_config
    stdlib_target = ctx.attr._stdlib_cached_metadata

    mypypath_parts = []
    direct_src_files = []
    direct_metadata_triples = []
    direct_imports = []
    transitive_srcs_depsets = []
    transitive_import_paths = []
    transitive_metadata_triples = []
    transitive_metadata_files = []
    stub_files = []
    stdlib_metadata_triples_param_file = None

    if hasattr(base_rule.attr, "srcs"):
        # Extract the srcs mentioned in .srcs as direct sources. These are source files that we
        # intend to mypy validate.
        direct_src_files = _extract_srcs(base_rule.attr.srcs)

    if is_test and hasattr(base_rule.attr, "deps"):
        # Extract the first-order source files. These are the source files of the *first degree*
        # deps, and no further.
        # This is mainly useful in tests, because usually a mypy_test() will have one or more deps,
        # which are the things you're actually interested in type checking.
        direct_src_files.extend(_extract_first_order_dep_srcs(base_rule.attr.deps))

        direct_imports = _extract_first_order_imports(base_rule.attr.deps)

    if hasattr(base_rule.attr, "deps"):
        # Transitive srcs are needed to check direct_src_files' usage of their interface(s). These
        # need to be available in the sandbox.
        transitive_srcs_depsets.extend(_extract_transitive_deps(base_rule.attr.deps))
        stub_files.extend(_extract_stub_deps(base_rule.attr.deps))

        # This is the set of import paths of all the PyInfo's in all the deps. This is necessary in
        # order to allow mypy to find all the imports and typecheck those as well. Without this,
        # only the primary 'imports' from the _extract_imports() function (below) is used, and this
        # is not always enough. I think the mypy rules assumed that all python imports happen wrt
        # the root (e.g. from a.b.c import d).
        transitive_import_paths = _extract_transitive_imports(ctx, base_rule.attr.deps)

        # Transitive metadata files and cache map triples also come from the deps.
        transitive_metadata_files = _extract_transitive_metadata_files(ctx, base_rule.attr.deps)
        transitive_metadata_triples = _extract_transitive_metadata_triples(ctx, base_rule.attr.deps)

    if hasattr(base_rule.attr, "imports"):
        direct_imports = _extract_imports(base_rule.attr.imports, ctx.label)

    # Extract information about the stdlib stubs and their (pre-)generated metadata. The
    # ._stdlib_cached_metadata attribute is always specified for mypy aspects and mypy_test targets.
    stdlib_metadata_triples_depset = _extract_transitive_metadata_triples(ctx, [stdlib_target])[0]
    transitive_metadata_files.extend(
        _extract_transitive_metadata_files(ctx, [stdlib_target]),
    )

    # The typeshed stdlib stub (pyi) files come from _stdlib_cached_metadata as well.
    stdlib_stub_files_depset = stdlib_target[MyPyStdLibCacheInfo].stdlib_stub_files
    stdlib_stub_anchor = stdlib_target[MyPyStdLibCacheInfo].stdlib_stub_anchor
    typeshed_dir = _get_stdlib_typeshed_dir_from_path(path_helper(stdlib_stub_anchor))

    transitive_srcs_depsets.append(stdlib_stub_files_depset)

    final_srcs_depset = depset(direct = direct_src_files, transitive = transitive_srcs_depsets)

    all_src_files = [f for f in final_srcs_depset.to_list() if not _is_external_src(f)]

    if not all_src_files:
        # By returning None, we keep the _impl functions that use this macro sane. See error
        # messages there.
        return None

    package_roots = sets.to_list(
        sets.make([f.root.path for f in all_src_files]),
    )

    mypypath_parts.extend([src_f.dirname for src_f in stub_files])
    mypypath_parts.extend(direct_imports)
    mypypath_parts.extend(transitive_import_paths)
    mypypath_parts.extend(package_roots)

    mypypath = ":".join(mypypath_parts)

    # Ideally, a file should be passed into this rule. If this is an executable
    # rule, then we default to the implicit executable file, otherwise we create
    # a stub.
    if is_test:
        if hasattr(ctx, "outputs"):
            exe = ctx.outputs.executable
        else:
            exe = ctx.actions.declare_file(
                "%s_mypy_exe" % base_rule.attr.name,
            )
        out = None
    else:  # is_aspect
        out = ctx.actions.declare_file("%s_dummy_out" % ctx.rule.attr.name)
        exe = ctx.actions.declare_file(
            "%s_mypy_exe" % ctx.rule.attr.name,
        )

    cache_map_triples = _sources_to_cache_map_triples(ctx, direct_src_files)

    # These are the Files representing the metadata output files that mypy generates for a given
    # library. They are my_lib_name.meta.json and my_lib_name.data.json.
    direct_metadata_files = []

    # These are the structs containing the source File, the meta File, and the data File. They are
    # kept together in structs, because the command line arguments to --cache-map must be grouped
    # correctly.
    direct_metadata_triples = []

    # mypy_test targets do not need to declare the metadata files, since they do not need to provide
    # them to dependencies.
    if not is_test:
        for cache_map_triple in cache_map_triples:
            # Declare the .meta.json and .data.json files as outputs.
            meta_declared = ctx.actions.declare_file(cache_map_triple.meta_filename)
            data_declared = ctx.actions.declare_file(cache_map_triple.data_filename)

            # Add the files to the list that will be provided by the MyPyAspectInfo provider.
            direct_metadata_triples.append(
                _MyPyCacheTripleInfo(
                    py = cache_map_triple.py,
                    meta = meta_declared,
                    data = data_declared,
                ),
            )

            direct_metadata_files.append(meta_declared)
            direct_metadata_files.append(data_declared)

    metadata_files_depset = depset(
        direct = direct_metadata_files,
        transitive = transitive_metadata_files,
    )
    metadata_triples_depset = depset(
        direct = direct_metadata_triples,
        transitive = transitive_metadata_triples,
    )

    # See note below on why this is necessary.
    cache_map_triple_mypy_dict = {}

    cache_map_triple_mypy_args = ctx.actions.args()
    cache_map_triple_mypy_args.use_param_file("%s", use_always = True)

    # TODO: Avoid to_list() somehow. We can't quite use an Args object, because we need to uniquify
    # based on triple.py.path, while also excluding the triple's .meta and .data components (which
    # are unique already, because they contain the label; see _sources_to_cache_map_triples above).
    for cache_map_triple in metadata_triples_depset.to_list():
        # In some cases, it is possible to have the same source.py file duplicated in separate
        # --cache-map arguments. Consider for example:
        #
        # py_library(name = "a", srcs = ["a.py"])
        # py_library(name = "a_prime", srcs = ["a.py"])
        # py_binary(name = "bin", srcs = ["bin.py"], deps = [":a", ":a_prime"])
        #
        # There is nothing preventing this situation, and it's perfectly valid in terms of bazel
        # dependencies and python rules to have this. The runfiles will contain a.py and all is
        # fine.
        #
        # However, mypy expects --cache-map arguments for each python source file, and it does not
        # want duplicate --cache-map arguments pointing at the same a.py (it exits with an error in
        # this case). Since each py source file must have a unique --cache-map argument, we have a
        # dilemma, since both "a" and "a_prime" specify the same source. If we were to operate as
        # usual, both sets of --cache-map arguments would be in metadata_triples_depset, which is
        # bad.
        #
        # The solution is to just pick one cache map argument (the first one encountered). This is
        # not a perfect solution, though, since it is possible for the same py source file, at the
        # exact same location, to produce a different set of mypy metadata (for example, if the
        # python source file's import path was different). But this seems pathlogical enough to not
        # worry about it.
        if cache_map_triple.py.path in cache_map_triple_mypy_dict:
            continue

        cache_map_triple_mypy_dict[cache_map_triple.py.path] = 1

        cache_map_triple_mypy_args.add_all(
            [cache_map_triple.py, cache_map_triple.meta, cache_map_triple.data],
            map_each = path_helper,
        )

    cache_map_triple_mypy_args_param_file = ctx.actions.declare_file(
        "{}_cache_map_triples_param_file".format(ctx.label.name),
    )
    ctx.actions.write(
        cache_map_triple_mypy_args_param_file,
        cache_map_triple_mypy_args,
    )
    cache_map_triple_arg = path_helper(cache_map_triple_mypy_args_param_file)

    # To keep things somewhat clean, we can consolidate the stdlib metadata --cache-map argument
    # triples, and put them in a param file. Since there is quite a large number of stdlib stub
    # files, this can have a huge effect on debugging and watching the mypy command line execute
    # (via bazel -s). By keeping only the relevant target's arguments on the command line, we make
    # the task of debugging and reasoning about the executable script much saner. The common,
    # unchanging stdlib stubs' --cache-map arguments are hidden away in a @param file, which works
    # because mypy (the tool) supports the '@params.txt' argument format.
    stdlib_metadata_triples_param_file = ctx.actions.declare_file(
        "{}_stdlib_param_file".format(ctx.label.name),
    )

    stdlib_metadata_triples_args = ctx.actions.args()
    stdlib_metadata_triples_args.use_param_file("%s", use_always = True)
    stdlib_metadata_triples_args.add_all(
        stdlib_metadata_triples_depset,  # values
        map_each = _triple_to_list_of_shortpaths if is_test else _triple_to_list_of_paths,
    )

    # TODO: This file is created here in _mypy_rule_impl, rather than in the
    # mypy_stdlib_cache_library rule itself, which seems awkard. It is defined here, rather than
    # provided by mypy_stdlib_cache_library, because we need to do the .short_path/.path management
    # (see above paragraph). However, it makes sense for mypy_stdlib_cache_library to just provide
    # *two* different param files in this way, one using .short_path (for tests) and one using .path
    # (for aspects). Then _mypy_rule_impl has only to choose one of the two to pass as arguments to
    # the action below.
    ctx.actions.write(
        stdlib_metadata_triples_param_file,
        stdlib_metadata_triples_args,
    )

    stdlib_metadata_triples_arg = path_helper(stdlib_metadata_triples_param_file)

    modules_to_check = _direct_srcs_to_modules(direct_imports, direct_src_files)

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = exe,
        substitutions = {
            "{MYPY_EXE}": path_helper(ctx.executable._mypy_cli),
            "{MYPY_ROOT}": ctx.executable._mypy_cli.root.path,
            "{CACHE_MAP_TRIPLES_PARAM_FILE}": cache_map_triple_arg,
            "{STDLIB_METADATA_TRIPLES_PARAM_FILE}": stdlib_metadata_triples_arg,
            "{CUSTOM_TYPESHED_DIR}": typeshed_dir,
            "{PACKAGE_ROOTS}": " ".join([
                "--package-root " + shell.quote(path or ".")
                for path in package_roots
            ]),
            "{MODULES}": " ".join(["-m {}".format(m) for m in modules_to_check]),
            "{SRCS}": "",
            "{VERBOSE_OPT}": "--verbose" if DEBUG else "",
            "{VERBOSE_BASH}": "set -x" if DEBUG else "",
            "{OUTPUT}": out.path if out else "",
            "{IS_TEST}": "1" if is_test else "0",
            "{MYPYPATH_PATH}": mypypath if mypypath else "",
            "{MYPY_INI_PATH}": path_helper(mypy_config_file),
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = all_src_files + stub_files + [
            cache_map_triple_mypy_args_param_file,
            stdlib_metadata_triples_param_file,
            mypy_config_file,
        ],
        transitive_files = depset(
            transitive = transitive_metadata_files + [stdlib_stub_files_depset],
        ),
    )

    if is_test:
        runfiles = runfiles.merge(ctx.attr._mypy_cli.default_runfiles)

    return [
        DefaultInfo(executable = exe, runfiles = runfiles),
        MyPyAspectInfo(
            exe = exe,
            out = out,
            direct_imports = direct_imports,
            direct_metadata_files = direct_metadata_files,
            metadata_triples = metadata_triples_depset,
            metadata_files = metadata_files_depset,
        ),
    ]

_VALID_ASPECT_RULE_KINDS = ["py_binary", "py_library", "py_test", "mypy_stdlib_cache_library"]

def _mypy_aspect_impl(target, ctx):
    if (ctx.rule.kind not in _VALID_ASPECT_RULE_KINDS or
        ctx.label.workspace_root.startswith("external")):
        return []

    providers = _mypy_rule_impl(
        ctx,
        is_aspect = True,
    )
    if not providers:
        return []

    info = providers[0]
    aspect_info = providers[1]

    declared_metadata = aspect_info.direct_metadata_files

    ctx.actions.run(
        outputs = [aspect_info.out] + declared_metadata,
        inputs = info.default_runfiles.files,
        tools = [ctx.executable._mypy_cli],
        executable = aspect_info.exe,
        mnemonic = "MyPy",
        progress_message = "Type-checking %s" % ctx.label,
        use_default_shell_env = True,
    )
    return [
        aspect_info,
        OutputGroupInfo(
            mypy = depset([aspect_info.out]),
        ),
    ]

def _mypy_test_impl(ctx):
    providers = _mypy_rule_impl(
        ctx,
        is_aspect = False,
    )

    if not providers:
        fail("A list of python deps are required for mypy_test")

    default_info = providers[0]

    return default_info

def _mypy_stdlib_cache_library_impl(ctx):
    mypy_config_file = ctx.file._mypy_config

    direct_metadata_triples = []
    stdlib_metadata_files = []

    # The typeshed .pyi files are part of mypy's data files.
    stdlib_stub_files = [
        f
        for f in ctx.attr._mypy_pkg[DefaultInfo].data_runfiles.files.to_list()
        if _is_typeshed_src(f)
    ]

    out = ctx.actions.declare_file("%s_dummy_out" % ctx.attr.name)
    exe = ctx.actions.declare_file(
        "%s_mypy_exe" % ctx.attr.name,
    )

    src_root_paths = sets.to_list(
        sets.make([f.root.path for f in stdlib_stub_files]),
    )

    # The typeshed directory needs to be specified to pass to --custom-typeshed-dir (see the
    # template expansion). However, we can't put the typeshed directory (as a string) into a
    # provider field, because it might need to be relativized differently according to usage (f.path
    # vs. f.short_path, for tests). So instead, we pick an arbitrary stdlib_stub_files to serve as
    # the anchor. Aspects and test rules can use this anchor to tease out the typeshed_dir according
    # to their needs.
    stdlib_stub_anchor = stdlib_stub_files[0]
    typeshed_dir = _get_stdlib_typeshed_dir_from_path(stdlib_stub_anchor.path)

    for py in stdlib_stub_files:
        # The below action will generate the .meta.json and .data.json files from the given stdlib
        # stub file.
        meta = ctx.actions.declare_file(
            paths.join(
                CACHE_SUBDIR,
                paths.relativize(py.dirname, typeshed_dir),
                paths.replace_extension(py.basename, ".meta.json"),
            ),
        )
        data = ctx.actions.declare_file(
            paths.join(
                CACHE_SUBDIR,
                paths.relativize(py.dirname, typeshed_dir),
                paths.replace_extension(py.basename, ".data.json"),
            ),
        )
        direct_metadata_triples.append(
            _MyPyCacheTripleInfo(
                py = py,
                meta = meta,
                data = data,
            ),
        )

        stdlib_metadata_files.append(meta)
        stdlib_metadata_files.append(data)

    metadata_files_depset = depset(
        direct = stdlib_metadata_files,
        # No transitive; this is a leaf.
    )
    metadata_triples_depset = depset(
        direct = direct_metadata_triples,
        # No transitive; this is a leaf.
    )

    cache_map_triple_mypy_args = ctx.actions.args()
    cache_map_triple_mypy_args.use_param_file("%s", use_always = True)

    for cache_map_triple in direct_metadata_triples:
        cache_map_triple_mypy_args.add_all(
            [cache_map_triple.py, cache_map_triple.meta, cache_map_triple.data],
            map_each = _path_getter,
        )

    cache_map_triple_mypy_args_param_file = ctx.actions.declare_file(
        "{}_cache_map_triples_param_file".format(ctx.label.name),
    )
    ctx.actions.write(
        cache_map_triple_mypy_args_param_file,
        cache_map_triple_mypy_args,
    )
    cache_map_triple_arg = cache_map_triple_mypy_args_param_file.path

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = exe,
        substitutions = {
            "{MYPY_EXE}": ctx.executable._mypy_cli.path,
            "{MYPY_ROOT}": ctx.executable._mypy_cli.root.path,
            "{CACHE_MAP_TRIPLES_PARAM_FILE}": cache_map_triple_arg,
            "{STDLIB_METADATA_TRIPLES_PARAM_FILE}": "",
            "{CUSTOM_TYPESHED_DIR}": typeshed_dir,
            "{PACKAGE_ROOTS}": "",
            "{MODULES}": "",
            "{SRCS}": " ".join([
                shell.quote(f.path)
                for f in stdlib_stub_files
            ]),
            "{VERBOSE_OPT}": "--verbose" if DEBUG else "",
            "{VERBOSE_BASH}": "set -x" if DEBUG else "",
            "{OUTPUT}": out.path if out else "",
            "{IS_TEST}": "0",
            # No MYPYPATH:
            "{MYPYPATH_PATH}": "",
            "{MYPY_INI_PATH}": mypy_config_file.path,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = stdlib_stub_files + [mypy_config_file, cache_map_triple_mypy_args_param_file],
    )

    # For typing_extensions and other things that mypy needs, we need the _mypy_cli runfiles as
    # well. typing_extensions is a binary (.so) which is listed as a 'data' dependency, so we can
    # suffice with .data_runfiles.
    runfiles = runfiles.merge(ctx.attr._mypy_cli.data_runfiles)

    ctx.actions.run(
        outputs = [out] + stdlib_metadata_files,
        inputs = runfiles.files,
        tools = [ctx.executable._mypy_cli],
        executable = exe,
        mnemonic = "MyPy",
        progress_message = "StdLibMypy %s" % ctx.label,
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(executable = exe, runfiles = runfiles),
        MyPyAspectInfo(
            metadata_files = metadata_files_depset,
            metadata_triples = metadata_triples_depset,
        ),
        MyPyStdLibCacheInfo(
            stdlib_stub_anchor = stdlib_stub_anchor,
            stdlib_stub_files = depset(direct = stdlib_stub_files),
        ),
    ]

mypy_aspect = aspect(
    implementation = _mypy_aspect_impl,
    attr_aspects = ["deps"],
    attrs = dicts.add(
        DEFAULT_ATTRS,
        STDLIB_CACHED_METADATA_ATTRS,
    ),
)

mypy_test = rule(
    implementation = _mypy_test_impl,
    test = True,
    attrs = dicts.add(
        DEFAULT_ATTRS,
        STDLIB_CACHED_METADATA_ATTRS,
        {"deps": attr.label_list(
            aspects = [mypy_aspect],
            allow_empty = False,
        )},
    ),
)

mypy_stdlib_cache_library = rule(
    implementation = _mypy_stdlib_cache_library_impl,
    attrs = dicts.add(
        DEFAULT_ATTRS,
        {
            "_mypy_pkg": attr.label(
                default = requirement("mypy"),
            ),
        },
    ),
    provides = [
        MyPyStdLibCacheInfo,
        MyPyAspectInfo,
    ],
)
