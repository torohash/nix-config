{ mkShell, python312, uv, pyright, basedpyright, ruff }:

mkShell {
  packages = [
    python312
    uv
    # LSP,Linter,Formatterなど。
    pyright
    basedpyright
    ruff
  ];
}
