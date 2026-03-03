{ mkShell, python312, uv, ruff, basedpyright, pyright, stdenv }:

mkShell {
  packages = [
    python312
    uv
    # Linter, Formatterなど。
    ruff
    basedpyright
    pyright
  ];

  # numpy 等の C 拡張が libstdc++.so.6 を必要とする
  env.LD_LIBRARY_PATH = "${stdenv.cc.cc.lib}/lib";
}
