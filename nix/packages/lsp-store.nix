{ buildEnv, nixd, marksman, lua-language-server }:

buildEnv {
  name = "lsp-store";
  paths = [
    nixd
    marksman
    lua-language-server
  ];
}
