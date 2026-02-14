{ mkShell, python312, uv, ruff, basedpyright, pyright, python312Packages }:

mkShell {
  packages = [
    python312
    uv
    ruff
    basedpyright
    pyright
    python312Packages.jupyterlab
  ];
}
