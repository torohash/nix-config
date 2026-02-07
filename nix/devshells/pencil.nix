{ mkShell, appimageTools, fetchurl, lib, stdenv }:

let
  version = "1.1.17";
  appImageAsset =
    if stdenv.hostPlatform.system == "x86_64-linux" then {
      url = "https://github.com/highagency/pencil-desktop-releases/releases/download/v1.1.17/Pencil-1.1.17-linux-x86_64.AppImage";
      hash = "sha256-6CcxJ+y5jL4okw2xPCsiWRdP6GMT/jREHCai8wJSo8w=";
    } else if stdenv.hostPlatform.system == "aarch64-linux" then {
      url = "https://github.com/highagency/pencil-desktop-releases/releases/download/v1.1.17/Pencil-1.1.17-linux-arm64.AppImage";
      hash = "sha256-uG71M2YP5krLMIcbpc7bwTvItr+MlhKDDl6DlMgOdeg=";
    } else
      null;

  pencilDesktop =
    if appImageAsset == null then null else
      appimageTools.wrapType2 {
        pname = "pencil-desktop";
        inherit version;
        src = fetchurl {
          inherit (appImageAsset) url hash;
        };
      };
in
mkShell {
  packages = lib.optionals (pencilDesktop != null) [
    pencilDesktop
  ];
  shellHook = lib.optionalString (pencilDesktop == null) ''
    echo "pencil devShell is currently available on Linux only."
  '';
}
