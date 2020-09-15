load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//:mypy.bzl", "path_to_py_module")

def _basic_passing_test(ctx):
    """Unit tests for a basic library verification test."""
    env = unittest.begin(ctx)

    asserts.equals(env, "f", path_to_py_module("f.py"))
    asserts.equals(env, "some.module", path_to_py_module("some/module.py"))
    asserts.equals(env, "some.module", path_to_py_module("some/module/__init__.py"))

    return unittest.end(env)

basic_passing_test = unittest.make(_basic_passing_test)

def unittest_suite():
    unittest.suite(
        "bzl_unittest_tests",
        basic_passing_test,
    )
