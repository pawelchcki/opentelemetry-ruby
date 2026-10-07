"""An immutable Minitest dependency that runs on Ruby 1.9.3."""

def _minitest_impl(ctx):
    ctx.download(
        url = "https://rubygems.org/downloads/minitest-5.10.3.gem",
        sha256 = "e2cf53a5b01932bfea16a5c76855836ddf2240ad53bcfdb09e99a6c0290ba214",
        output = "source.tar",
    )
    ctx.extract("source.tar", output = "package")
    ctx.extract("package/data.tar.gz", output = "minitest")
    ctx.file("BUILD.bazel", """package(default_visibility = ["//visibility:public"])
exports_files(["minitest/lib/minitest.rb"])
filegroup(name = "library", srcs = glob(["minitest/lib/**"]))
""")

minitest_repository = repository_rule(implementation = _minitest_impl)
