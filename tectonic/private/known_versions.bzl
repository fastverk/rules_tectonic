"""Pinned tectonic release shas, keyed by version + canonical platform.

Add new versions here as the upstream releases; everything downstream
(extensions.bzl, toolchain registration) picks up the new entry
automatically.

Canonical platform names follow the rules_github convention:
`<os>_<arch>` from {darwin, linux, windows} x {aarch64, x86_64}.
"""

DEFAULT_VERSION = "0.15.0"

# `repo = "tectonic-typesetting/tectonic"` is constant; release tag
# format is `tectonic@<version>` (the Cargo-workspace tag prefix).
TECTONIC_REPO = "tectonic-typesetting/tectonic"
TECTONIC_TAG_FORMAT = "tectonic@{version}"

# Upstream uses Rust-target triples in the asset filenames. We bake the
# archive extension into the alias so `asset_template` is a single
# static string (rules_github only substitutes `{version}` and
# `{platform}`).
PLATFORM_ALIASES = {
    "darwin_aarch64": "aarch64-apple-darwin.tar.gz",
    "darwin_x86_64":  "x86_64-apple-darwin.tar.gz",
    "linux_aarch64":  "aarch64-unknown-linux-musl.tar.gz",
    "linux_x86_64":   "x86_64-unknown-linux-musl.tar.gz",
}

# sha256 per (version, platform). Add to this dict when bumping
# DEFAULT_VERSION; missing entries fail at fetch time with a clear
# message from rules_github.
KNOWN_SHAS = {
    "0.15.0": {
        "darwin_aarch64": "24bd46566fa30d41101848405e9cbc4645edb92d8f857c9d21262174fb70cd33",
        "darwin_x86_64":  "dd42576eaa4c0df58c243dd78b7b864d9deb405ffdfcdadd1b79a31faceab747",
        "linux_aarch64":  "1f59f9fb8eb65e8ba18658fc9016767e7d3e12488ded8b8fffa34254e51ce42c",
        "linux_x86_64":   "dfb82876f2986862996e564fa507a9e576e0c1e3bee63c2c1bd677c2543e6407",
    },
}
