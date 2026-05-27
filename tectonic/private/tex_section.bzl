"""tex_section — typed section fragment for `tex_paper`.

A `tex_section` wraps a single `.tex` file that will be
`\\input{}`'d by an assembled paper main.tex. The section is its
own build target so it can:

  * Carry typed metadata (section label, citations used, Lean
    emit deps) that the `tex_paper` aggregator can validate.
  * Be reused across papers without copy-paste.
  * Cache independently — editing one section doesn't rebuild
    the entire paper's compile graph.

```starlark
tex_section(
    name = "semantics",
    src = "sections/semantics.tex",
    label = "sec:semantics",
    cites = ["chandra1977optimal", "vickrey1961counterspeculation"],
    lean_emits = ["//lean:vickrey_rule_tex_generated"],
)
```

v0.0.2: providers carry metadata; validation (cite ⊆ bib,
section labels unique) is `tex_paper`'s job and lands in v0.0.3
alongside a `tex_bibliography` rule.
"""

TexSectionInfo = provider(
    doc = "A typed paper section.",
    fields = {
        "src": "File — the section's .tex source.",
        "label": "str — `\\label{sec:...}` declared by the section. Empty if not declared.",
        "cites": "list[str] — bibtex-key citations the section uses; checked against the paper's bibliography by tex_paper.",
        "lean_emits": "list[File] — Lean-emitted .tex fragments the section depends on (so tex_paper can stage them).",
        "extra_srcs": "list[File] — non-Lean extra inputs (figures, .sty, etc.) the section references.",
    },
)

def _tex_section_impl(ctx):
    # `DefaultInfo.files` exposes the section .tex AND its Lean
    # emits + extra srcs. This means `tex_paper` can pass each
    # section into `tectonic_pdf.srcs` directly and tectonic's
    # staging picks up everything the section needs to compile —
    # no separate dependency threading required.
    all_files = [ctx.file.src] + ctx.files.lean_emits + ctx.files.extra_srcs
    return [
        DefaultInfo(files = depset(all_files)),
        TexSectionInfo(
            src = ctx.file.src,
            label = ctx.attr.section_label,
            cites = ctx.attr.cites,
            lean_emits = ctx.files.lean_emits,
            extra_srcs = ctx.files.extra_srcs,
        ),
    ]

tex_section = rule(
    implementation = _tex_section_impl,
    attrs = {
        "src": attr.label(
            allow_single_file = [".tex"],
            mandatory = True,
            doc = "The section's .tex file (no preamble, no `\\begin{document}`; just the section body).",
        ),
        "section_label": attr.string(
            default = "",
            doc = "Section label as declared via `\\label{...}` inside the section; informational at v0.0.2.",
        ),
        "cites": attr.string_list(
            doc = "Bibtex keys cited by this section. v0.0.3 cross-checks against the paper's bibliography.",
        ),
        "lean_emits": attr.label_list(
            allow_files = True,
            doc = "Lean-emitted .tex fragments this section `\\input{}`s.",
        ),
        "extra_srcs": attr.label_list(
            allow_files = True,
            doc = "Non-Lean extra inputs (figures, included .sty files, embedded data).",
        ),
    },
)
