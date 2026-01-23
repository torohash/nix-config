{ buildEnv, nixd, marksman, pyright, basedpyright, lua-language-server }:

buildEnv {
  name = "lsp-store";
  paths = [
    nixd
    marksman
    pyright
    basedpyright
    lua-language-server
  ];
}
