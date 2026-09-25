{
  description = "Generic config store with common tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixgl }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      homeSystem = "x86_64-linux";
      homeUsername = "torohash";
      homePlatforms = [
        "ubuntu"
        "fedora"
        "wsl"
        "omarchy"
      ];
      isIntelX86Platform = homeSystem == "x86_64-linux";
      # nixGL は固定した版のままだと現在の nixpkgs でビルドできないため、
      # 入力のソースへ互換修正を当てて読み込む。
      fedoraNixglSrc = nixpkgs.legacyPackages.${homeSystem}.applyPatches {
        name = "nixGL-patched";
        src = nixgl.outPath;
        patches = [
          ./nix/patches/nixgl-latest-nixpkgs.patch
          ./nix/patches/nixgl-egl-external-platforms.patch
          ./nix/patches/nixgl-gbm-backends-path.patch
          ./nix/patches/nixgl-nvidia-version-autodetect.patch
        ];
      };
      # NVIDIA ドライバー版は nixGL が /proc/driver/nvidia/version から読む。
      # そのビルドは builtins.currentTime を使うため、Fedora の構成は
      # --impure を付けて評価する。
      fedoraNixglPkgs = import fedoraNixglSrc {
        pkgs = import nixpkgs {
          system = homeSystem;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "nvidia"
              "nvidia-x11"
            ];
        };
        enable32bits = isIntelX86Platform;
        enableIntelX86Extensions = isIntelX86Platform;
      };
      fedoraNixglPackages = nixgl.packages // {
        ${homeSystem} = nixgl.packages.${homeSystem} // {
          nixGLNvidia = fedoraNixglPkgs.auto.nixGLNvidia;
          nixVulkanNvidia = fedoraNixglPkgs.auto.nixVulkanNvidia;
        };
      };
      nixglPackagesFor = platform:
        if platform == "fedora" then
          fedoraNixglPackages
        else
          nixgl.packages;
      hostModule = platform:
        ./nix/home/hosts + "/${homeUsername}_${platform}.nix";
      mkHomeConfiguration = platform:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${homeSystem};
          extraSpecialArgs = {
            nixgl = nixgl // {
              packages = nixglPackagesFor platform;
            };
          };
          modules = [
            (hostModule platform)
          ];
        };
      homeConfigurations = nixpkgs.lib.listToAttrs (map
        (platform: {
          name = "${homeUsername}_${platform}";
          value = mkHomeConfiguration platform;
        })
        homePlatforms);
      mkPackages = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "terraform"
              ];
          };
          stores = import ./nix/lib/stores.nix { inherit pkgs; };
        in
        rec {
          common-store = stores.common;
          lsp-store = stores.lsp;
          default = stores.common;
        };
      mkDevShells = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          androidPkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          devshells = import ./nix/lib/devshells.nix { inherit pkgs androidPkgs; };
          pythonShell = devshells.python;
          typescriptShell = devshells.typescript;
          pencilShell = devshells.pencil;
          jupyterlabShell = devshells.jupyterlab;
          godotShell = devshells.godot;
          flutterShell = devshells.flutter;
        in
        {
          python = pythonShell;
          typescript = typescriptShell;
          pencil = pencilShell;
          jupyterlab = jupyterlabShell;
          godot = godotShell;
          flutter = flutterShell;
          default = pythonShell;
        };
      mkChecks = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
          openwhisprUinputUdevRule =
            ./host/fedora/udev/72-openwhispr-uinput.rules;
          herdrConfigFile = ./dotfiles/herdr/config.toml;
          herdrConfig = builtins.fromTOML (builtins.readFile herdrConfigFile);
          expectedHerdrKeyBindings = {
            prefix = "alt+s";
            previous_workspace = "prefix+a";
            next_workspace = "prefix+d";
            previous_agent = "prefix+shift+a";
            next_agent = "prefix+shift+d";
            close_workspace = "prefix+shift+q";
          };
          herdrKeyBindingsAreExpected = lib.all
            (name: (herdrConfig.keys or {}).${name} or null
              == expectedHerdrKeyBindings.${name})
            (builtins.attrNames expectedHerdrKeyBindings);
          herdrKeyBindingsAreUnique = builtins.length
            (builtins.attrValues expectedHerdrKeyBindings)
            == builtins.length
              (lib.unique (builtins.attrValues expectedHerdrKeyBindings));
          herdrOnboardingIsDisabled = (herdrConfig.onboarding or null) == false;
          # OmarchyはHerdr設定を自前で配置するため、Home Managerの管理対象から外す。
          herdrHomeConfigurations = builtins.attrValues (lib.filterAttrs
            (name: _: name != "${homeUsername}_omarchy")
            homeConfigurations);
          herdrConfigIsHomeManagerManaged = lib.all
            (homeConfiguration:
              let
                configFile =
                  homeConfiguration.config.xdg.configFile."herdr/config.toml"
                    or null;
              in
              configFile != null
              && configFile.target == ".config/herdr/config.toml")
            herdrHomeConfigurations;
          omarchyHomeConfiguration =
            homeConfigurations."${homeUsername}_omarchy";
          omarchyManagedFiles = builtins.attrValues
            omarchyHomeConfiguration.config.home.file;
          # Omarchyが配置・テーマ追従・refreshするファイル。
          # Home Managerが持つと互いに上書きし合う。
          omarchyOwnedTargets = [
            ".bashrc"
            ".bash_profile"
            ".profile"
            ".tmux.conf"
            ".gitconfig"
            ".config/git/config"
            ".config/ghostty/config"
            ".config/alacritty/alacritty.toml"
            ".config/btop/btop.conf"
            ".config/lazygit/config.yml"
            ".config/starship.toml"
            ".config/tmux/tmux.conf"
            ".config/herdr/config.toml"
            ".config/fcitx5/config"
            ".config/fcitx5/profile"
            ".config/mise/config.toml"
            # ツールとOmarchyも書き込むため、Home Managerでは持たない。
            ".claude/settings.json"
            ".config/opencode/opencode.json"
            ".pi/agent/settings.json"
          ];
          omarchyOwnedDirectories = [
            ".config/hypr"
            ".config/omarchy"
            ".config/nvim"
          ];
          omarchyDoesNotManageOwnedFiles = lib.all
            (file:
              !(builtins.elem file.target omarchyOwnedTargets)
              && !(lib.any
                (directory: file.target == directory
                  || lib.hasPrefix "${directory}/" file.target)
                omarchyOwnedDirectories))
            omarchyManagedFiles;
          # Omarchyはこれらのskillsディレクトリに自前のskillをsymlinkする。
          # ディレクトリごとsymlinkにするとOmarchyのskillが見えなくなる。
          omarchySkillDirectories = [
            ".agents/skills"
            ".claude/skills"
            ".codex/skills"
            ".pi/agent/skills"
          ];
          omarchyKeepsSkillDirectories = lib.all
            (file:
              !(builtins.elem file.target omarchySkillDirectories)
              || file.recursive)
            omarchyManagedFiles;
          omarchyDoesNotManageInputMethod =
            !omarchyHomeConfiguration.config.i18n.inputMethod.enable;
        in
        {
          # 複数のローカル設定を読む静的検査なので、テストサイズはMediumとする。
          herdr-config-medium =
            assert lib.assertMsg herdrKeyBindingsAreExpected
              "Herdrのprefix・移動キー・workspaceを閉じるキーが期待値と一致しません";
            assert lib.assertMsg herdrKeyBindingsAreUnique
              "Herdrのprefix・移動キー・workspaceを閉じるキーが重複しています";
            assert lib.assertMsg herdrOnboardingIsDisabled
              "HerdrがHome Manager管理ファイルへ初回設定を書き込もうとします";
            assert lib.assertMsg herdrConfigIsHomeManagerManaged
              "Herdr設定が全Home Configurationで管理されていません";
            pkgs.runCommand "herdr-config-medium" { } ''
              mkdir -p "$out"
              echo "Herdr設定とキーバインドは正常です" > "$out/result"
            '';

          # Home Configurationを評価する静的検査なので、テストサイズはMediumとする。
          omarchy-ownership-medium =
            assert lib.assertMsg omarchyDoesNotManageOwnedFiles
              "Omarchyが管理するファイルをHome Managerが管理しています";
            assert lib.assertMsg omarchyKeepsSkillDirectories
              "OmarchyのskillsディレクトリをHome Managerがディレクトリごと置き換えます";
            assert lib.assertMsg omarchyDoesNotManageInputMethod
              "Omarchyのfcitx5とは別にHome Managerが入力メソッドを起動します";
            pkgs.runCommand "omarchy-ownership-medium" { } ''
              mkdir -p "$out"
              echo "Omarchyとの所有範囲の分担は正常です" > "$out/result"
            '';
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          # ローカルファイルを外部コマンドのudevadmで読む検査なので、テストサイズはMediumとする。
          openwhispr-uinput-udev-rule-medium = pkgs.runCommand
            "openwhispr-uinput-udev-rule-medium"
            {
              nativeBuildInputs = [
                pkgs.gnugrep
                pkgs.systemd
              ];
              udevRule = openwhisprUinputUdevRule;
            }
            ''
              udevadm verify "$udevRule"
              if ! grep -Fqx \
                'SUBSYSTEM=="misc", KERNEL=="uinput", OWNER="root", GROUP="root", MODE="0600", TAG+="uaccess"' \
                "$udevRule"; then
                echo "OpenWhispr用udevルールの対象または最小権限設定が期待値と一致しません" >&2
                exit 1
              fi

              mkdir -p "$out"
              echo "OpenWhispr用udevルールの構文と最小権限設定は正常です" > "$out/result"
            '';
        };
    in
    {
      packages = forAllSystems mkPackages;
      devShells = forAllSystems mkDevShells;
      checks = forAllSystems mkChecks;
      homeConfigurations = homeConfigurations;
    };
}
