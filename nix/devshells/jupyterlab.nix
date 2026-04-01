{ mkShell, python312, uv, ruff, basedpyright, pyright, python312Packages, stdenv, lib, zlib }:

mkShell {
  packages = [
    python312
    uv
    ruff
    basedpyright
    pyright
    python312Packages.jupyterlab
  ];

  # numpy/pandas 等の C 拡張が libstdc++.so.6, libz.so.1 を必要とする。
  # joblib/loky のワーカープロセスにも伝播させるために必要。
  shellHook = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ stdenv.cc.cc.lib zlib ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';
}
