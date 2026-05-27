"""Public API for rules_tectonic.

```starlark
load("@rules_tectonic//tectonic:defs.bzl",
     "tectonic_pdf", "tex_section", "tex_paper", "TexSectionInfo")
```

* `tectonic_pdf` (v0.1.x) — single-document compile. Use when
  the paper is a monolithic `main.tex`.
* `tex_section` + `tex_paper` (v0.0.2 of this surface) — typed
  section fragments composed into a paper. Each section is a
  build target carrying metadata (label, cites, Lean-emit deps);
  `tex_paper` generates the wrapper main.tex, threads the deps
  through `tectonic_pdf`, and produces the PDF. Use when sections
  want independent caching, reuse across papers, or eventual
  build-time validation (cite ⊆ bib, unique labels — v0.0.3).
"""

load("//tectonic/private:tectonic_pdf.bzl", _tectonic_pdf = "tectonic_pdf")
load(
    "//tectonic/private:tex_section.bzl",
    _TexSectionInfo = "TexSectionInfo",
    _tex_section = "tex_section",
)
load("//tectonic/private:tex_paper.bzl", _tex_paper = "tex_paper")

tectonic_pdf = _tectonic_pdf
tex_section = _tex_section
tex_paper = _tex_paper
TexSectionInfo = _TexSectionInfo
