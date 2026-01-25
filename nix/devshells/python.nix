{ mkShell, python312, uv, ruff, basedpyright }:

mkShell {
  packages = [
    python312
    uv
    # Linter, Formatterなど。
    ruff
    basedpyright
  ];
}
