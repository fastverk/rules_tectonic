"""Toolchain plumbing for tectonic.

`tectonic_toolchain` packages the fetched binary into a
`TectonicToolchainInfo` provider that `tectonic_pdf` resolves at build
time. Mirrors the rules_mdbook structure so the eventual extraction to
`rules_tectonic` is a directory move.
"""

TectonicToolchainInfo = provider(
    doc = "Tectonic binary needed to compile LaTeX → PDF.",
    fields = {
        "tectonic": "Executable File for the tectonic binary.",
    },
)

def _tectonic_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        tectonicinfo = TectonicToolchainInfo(
            tectonic = ctx.executable.tectonic,
        ),
    )]

tectonic_toolchain = rule(
    implementation = _tectonic_toolchain_impl,
    attrs = {
        "tectonic": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            doc = "The tectonic binary (single executable file).",
        ),
    },
    doc = "Wraps a tectonic binary as a registerable Bazel toolchain.",
)
