{ buildEnv, neovim }:

buildEnv {
  name = "neovim-store";
  paths = [
    neovim
  ];
}
