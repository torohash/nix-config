{ mkShell, python312, uv, ruff, basedpyright, python312Packages }:

mkShell {
  packages = [
    python312
    uv
    ruff
    basedpyright
    python312Packages.jupyterlab
  ];
}
