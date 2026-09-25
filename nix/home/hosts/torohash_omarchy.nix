{ ... }:
{
  # Omarchyが管理するシェル・エディタ・git・端末と競合するため、
  # common/modules.nix は読み込まない (platforms/omarchy/modules.nix を参照)。
  imports = [
    ../users/torohash.nix
    ../platforms/omarchy/modules.nix
  ];
}
