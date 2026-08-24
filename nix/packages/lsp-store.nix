{
  buildEnv,
  nixd,
  marksman,
  lua-language-server,
  dotnet-sdk_10,
  csharp-ls,
}:

buildEnv {
  name = "lsp-store";
  paths = [
    nixd
    marksman
    lua-language-server
    dotnet-sdk_10
    csharp-ls
  ];
}
