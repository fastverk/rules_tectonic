"""Public API for rules_tectonic.

Currently exposes one rule:

    load("@rules_tectonic//tectonic:defs.bzl", "tectonic_pdf")

    tectonic_pdf(
        name = "paper",
        main = "main.tex",
        srcs = ["arxiv.sty", "figs/loss_curve.png", "refs.bib"],
    )

`bazel build //paper:paper` produces `paper.pdf` in `bazel-bin`.
"""

load("//tectonic/private:tectonic_pdf.bzl", _tectonic_pdf = "tectonic_pdf")

tectonic_pdf = _tectonic_pdf
