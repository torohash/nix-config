{ buildEnv, python312, uv, pyright, basedpyright, ruff }:

buildEnv {
  name = "python-store";
  paths = [
    python312
    uv
    # LSP,Linter,Formatterなど。
    pyright
    basedpyright
    ruff
  ];
}
