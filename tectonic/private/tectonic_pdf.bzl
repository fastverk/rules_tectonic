"""Implementation of `tectonic_pdf`.

A `tectonic_pdf` target runs tectonic in single-document mode (`-X
compile`) on a designated `main.tex`. All inputs (the .tex itself and
everything in `srcs`) are staged into a unified workspace-rooted
directory so that relative paths in the .tex (`\\includegraphics{figs/x.png}`,
`\\usepackage{../mystyle}`) resolve consistently regardless of whether
each asset is source-vendored or genrule-produced.

Why staging is needed: bazel sandboxes place source files at their
workspace-relative paths and generated files under `bazel-out/...`.
Tectonic resolves relative-path includes from the .tex's directory,
which works for source assets but not for genrule outputs sitting in
a different subtree. We bridge the gap by copying every input into a
temp directory under its workspace-relative path, then invoking
tectonic from the staged .tex's directory.
"""

def _tectonic_pdf_impl(ctx):
    info = ctx.toolchains["//tectonic:toolchain_type"].tectonicinfo
    out_pdf = ctx.actions.declare_file(ctx.label.name + ".pdf")
    intermediate_base = ctx.file.main.basename.rsplit(".", 1)[0]

    inputs = [ctx.file.main] + ctx.files.srcs

    # Build a sequence of stage commands. For each input, mirror its
    # workspace-relative path inside $STAGE so all relative includes
    # in the .tex resolve uniformly.
    stage_lines = ['STAGE=$(mktemp -d) && EXEC=$(pwd)']
    seen_dirs = {}
    for inp in inputs:
        sp = inp.short_path
        parts = sp.rsplit("/", 1)
        sp_dir = parts[0] if len(parts) > 1 else "."
        if sp_dir not in seen_dirs:
            stage_lines.append('mkdir -p "$STAGE/{}"'.format(sp_dir))
            seen_dirs[sp_dir] = True
        stage_lines.append(
            'cp -L "$EXEC/{src}" "$STAGE/{dst}"'.format(src = inp.path, dst = sp),
        )

    main_sp = ctx.file.main.short_path
    main_sp_dir = main_sp.rsplit("/", 1)[0] if "/" in main_sp else "."
    main_basename = ctx.file.main.basename
    cmd = " && ".join(stage_lines + [
        'TECTONIC="$EXEC/{}"'.format(info.tectonic.path),
        'OUT_PDF="$EXEC/{}"'.format(out_pdf.path),
        'cd "$STAGE/{}"'.format(main_sp_dir),
        '"$TECTONIC" -X compile --outdir . --keep-logs "{}"'.format(main_basename),
        'mv "{}.pdf" "$OUT_PDF"'.format(intermediate_base),
    ])

    ctx.actions.run_shell(
        command = cmd,
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
            doc = "Additional input files (figures, .sty, .bib, included .tex). " +
                  "May include genrule outputs; the rule stages all inputs " +
                  "into a unified working dir so relative paths in the .tex " +
                  "resolve regardless of source vs. generated origin.",
        ),
    },
    toolchains = ["//tectonic:toolchain_type"],
    doc = "Compile a single .tex (plus its sources) into a PDF via tectonic.",
)
