{ mkShell, python312, uv, ruff, basedpyright, pyright, stdenv, lib, zlib }:

mkShell {
  packages = [
    python312
    uv
    # Linter, Formatterなど。
    ruff
    basedpyright
    pyright
  ];

  # numpy/pandas 等の C 拡張が libstdc++.so.6, libz.so.1 を必要とする。
  # env.LD_LIBRARY_PATH だと home-manager (nixGL) のパスを上書きするため、
  # shellHook で既存パスに追記する。
  shellHook = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ stdenv.cc.cc.lib zlib ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';
}
