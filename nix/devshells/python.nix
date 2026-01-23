{ mkShell, python312, uv, ruff }:

mkShell {
  packages = [
    python312
    uv
    # Linter, Formatterなど。
    ruff
  ];
}
