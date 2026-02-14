{ mkShell, python312, uv, ruff, basedpyright, pyright }:

mkShell {
  packages = [
    python312
    uv
    # Linter, Formatterなど。
    ruff
    basedpyright
    pyright
  ];
}
