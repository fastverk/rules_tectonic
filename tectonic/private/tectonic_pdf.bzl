"""Implementation of `tectonic_pdf`.

A `tectonic_pdf` target runs tectonic in single-document mode (`-X
compile`) on a designated `main.tex`, with any extra `srcs` (figures,
.sty files, .bib) staged into the action's input tree alongside it.
Tectonic's network fetcher is disabled (`--web-bundle=`) so we don't
go to the internet during the build; the default offline cache bundle
shipped with the binary is used instead.
"""

def _tectonic_pdf_impl(ctx):
    info = ctx.toolchains["//tectonic:toolchain_type"].tectonicinfo
    out_pdf = ctx.actions.declare_file(ctx.label.name + ".pdf")
    out_dir = out_pdf.dirname

    # Tectonic's `-X compile` writes <basename(main)>.pdf to --outdir,
    # ignoring our declared filename. Capture it via a tiny shell
    # wrapper that runs tectonic then renames the output. Keeping the
    # rename in-process (rather than a downstream genrule) preserves
    # the single-action model so bazel's caching key includes the
    # final PDF, not the intermediate.
    intermediate_base = ctx.file.main.basename.rsplit(".", 1)[0]
    inputs = [ctx.file.main] + ctx.files.srcs
    ctx.actions.run_shell(
        command = (
            "{tectonic} -X compile --outdir {outdir} --keep-logs {main} && " +
            "mv {outdir}/{base}.pdf {target}"
        ).format(
            tectonic = info.tectonic.path,
            outdir = out_dir,
            main = ctx.file.main.path,
            base = intermediate_base,
            target = out_pdf.path,
        ),
        tools = [info.tectonic],
        inputs = inputs,
        outputs = [out_pdf],
        mnemonic = "TectonicPdf",
        progress_message = "Compiling %{label} with tectonic",
        # Tectonic touches HOME for its bundle cache; pass through so
        # the user's existing cache is reused across invocations.
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([out_pdf]))]

tectonic_pdf = rule(
    implementation = _tectonic_pdf_impl,
    attrs = {
        "main": attr.label(
            allow_single_file = [".tex"],
            mandatory = True,
            doc = "The top-level .tex file passed to tectonic.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Additional input files (figures, .sty, .bib, included .tex).",
        ),
    },
    toolchains = ["//tectonic:toolchain_type"],
    doc = "Compile a single .tex (plus its sources) into a PDF via tectonic.",
)
