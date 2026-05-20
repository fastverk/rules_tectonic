"""Module extension that fetches the tectonic binary for the host.

Default usage::

    tectonic = use_extension("@rules_tectonic//tectonic:extensions.bzl", "tectonic")
    use_repo(tectonic, "tectonic")
    register_toolchains("@tectonic//:tectonic_toolchain_def")

Pin a non-default version::

    tectonic = use_extension("@rules_tectonic//tectonic:extensions.bzl", "tectonic")
    tectonic.toolchain(version = "0.15.0")
    use_repo(tectonic, "tectonic")
"""

load("@rules_github//github:repositories.bzl", "github_binary_repository")
load(
    "//tectonic/private:known_versions.bzl",
    "DEFAULT_VERSION",
    "KNOWN_SHAS",
    "PLATFORM_ALIASES",
    "TECTONIC_REPO",
    "TECTONIC_TAG_FORMAT",
)

# BUILD overlay dropped into the fetched binary repo: exports the
# binary and wires the toolchain so a top-level `register_toolchains`
# call is enough.
_BUILD_OVERLAY = """\
package(default_visibility = ["//visibility:public"])

load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@rules_tectonic//tectonic:toolchains.bzl", "tectonic_toolchain")

exports_files(["tectonic"])

# Wrap the raw release binary as a runnable target so the toolchain
# can declare it as an `executable` attribute.
native_binary(
    name = "tectonic_bin",
    src = "tectonic",
    out = "tectonic_bin",
)

tectonic_toolchain(
    name = "tectonic_toolchain",
    tectonic = ":tectonic_bin",
)

toolchain(
    name = "tectonic_toolchain_def",
    toolchain = ":tectonic_toolchain",
    toolchain_type = "@rules_tectonic//tectonic:toolchain_type",
)
"""

def _tectonic_impl(module_ctx):
    version = DEFAULT_VERSION
    for mod in module_ctx.modules:
        for tag in mod.tags.toolchain:
            version = tag.version
    if version not in KNOWN_SHAS:
        fail("tectonic version {} not pinned in known_versions.bzl; add platform shas there before referencing it".format(version))
    github_binary_repository(
        name = "tectonic",
        repo = TECTONIC_REPO,
        version = version,
        tag_format = TECTONIC_TAG_FORMAT,
        # `asset_template` runs after `platform_aliases` resolves
        # `{platform}` to the per-platform suffix (which already
        # contains the archive extension).
        asset_template = "tectonic-{version}-{platform}",
        # The release tarballs unpack directly to a single `tectonic`
        # executable at the archive root — no inner directory.
        strip_prefix_template = "",
        platform_aliases = PLATFORM_ALIASES,
        platform_shas = KNOWN_SHAS[version],
        build_file_content = _BUILD_OVERLAY,
    )

_toolchain_tag = tag_class(
    attrs = {
        "version": attr.string(
            default = DEFAULT_VERSION,
            doc = "tectonic release version, e.g. \"0.15.0\".",
        ),
    },
)

tectonic = module_extension(
    implementation = _tectonic_impl,
    tag_classes = {"toolchain": _toolchain_tag},
    doc = "Fetches a prebuilt tectonic binary for the host platform.",
)
