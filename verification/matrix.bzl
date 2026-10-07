"""Run the local fork against every pinned rules_stests Ruby interpreter."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

_RUNTIMES = [
    ("1_9_3", "1.9.1"),
    ("2_0", "2.0.0"),
    ("2_1", "2.1.0"),
    ("2_2", "2.2.0"),
    ("2_3", "2.3.0"),
    ("2_4", "2.4.0"),
    ("2_5", "2.5.0"),
    ("2_6", "2.6.0"),
    ("2_7", "2.7.0"),
    ("3_0", "3.0.0"),
    ("3_1", "3.1.0"),
    ("3_2", "3.2.0"),
    ("3_3", "3.3.0"),
    ("3_4", "3.4.0"),
    ("4_0", "4.0.0"),
]

def legacy_runtime_matrix(name):
    """Declare one test per MRI series and an aggregate suite.

    Args:
        name: Name of the aggregate test suite.
    """
    tests = []
    for series, abi in _RUNTIMES:
        runtime = "@rules_stests//fixtures:ruby_" + series + "_runtime"
        test_name = "ruby_" + series + "_test"
        sh_test(
            name = test_name,
            size = "small",
            srcs = ["runtime_test.sh"],
            args = [
                "$(rootpath {})".format(runtime),
                abi,
                "$(rootpath @legacy_minitest//:minitest/lib/minitest.rb)",
                "$(rootpath :test/runtime_test.rb)",
            ],
            data = [
                runtime,
                "test/runtime_test.rb",
                "//:trace_sdk_sources",
                "@legacy_minitest//:library",
                "@legacy_minitest//:minitest/lib/minitest.rb",
            ],
            target_compatible_with = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
            tags = ["ruby-matrix"],
        )
        tests.append(":" + test_name)
    native.test_suite(name = name, tests = tests)
