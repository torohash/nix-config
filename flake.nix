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
      ];
      isIntelX86Platform = homeSystem == "x86_64-linux";
      fedoraNvidiaDriver =
        {
          # Keep these in sync with the Fedora host driver. Dynamic /proc
          # detection would require impure IFD, and nixGL's auto regex does not
          # handle the NVIDIA Open Kernel Module version format.
          version = "595.80";
          # Hash of NVIDIA-Linux-x86_64-595.80.run. Update with the version.
          hash = "sha256-PVTIP+B/01c/8M66hXTAYTLg9T2Hy9u1gq43K7TF1Hg=";
        };
      fedoraNixglPkgs = import nixgl {
        pkgs = import nixpkgs {
          system = homeSystem;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "nvidia"
              "nvidia-x11"
            ];
        };
        nvidiaVersion = fedoraNvidiaDriver.version;
        nvidiaHash = fedoraNvidiaDriver.hash;
        enable32bits = isIntelX86Platform;
        enableIntelX86Extensions = isIntelX86Platform;
      };
      fedoraNixglPackages = nixgl.packages // {
        ${homeSystem} = nixgl.packages.${homeSystem} // {
          nixGLNvidia = fedoraNixglPkgs.nixGLNvidia;
          nixVulkanNvidia = fedoraNixglPkgs.nixVulkanNvidia;
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
          codexGlobalRulesFile = ./dotfiles/codex/AGENTS.md;
          opencodeAgentDirectory = ./dotfiles/opencode/agents;
          opencodeSkillDirectory = ./dotfiles/opencode/skills;
          opencodeGlobalRulesFile = ./dotfiles/opencode/AGENTS.md;
          opencodeConfig = builtins.fromJSON
            (builtins.readFile ./dotfiles/opencode/opencode.json);
          codexGlobalRulesFileExists =
            builtins.pathExists codexGlobalRulesFile;
          codexGlobalRulesAreHomeManagerManaged = lib.all
            (homeConfiguration:
              let
                configFile =
                  homeConfiguration.config.home.file.".codex/AGENTS.md" or null;
              in
              configFile != null
              && configFile.target == ".codex/AGENTS.md")
            (builtins.attrValues homeConfigurations);
          opencodeAgentFileNames = builtins.attrNames (lib.filterAttrs
            (fileName: _: lib.hasSuffix ".md" fileName)
            (builtins.readDir opencodeAgentDirectory));
          expectedOpencodeAgentModels = {
            "code-review.md" = {
              model = "openai/gpt-5.6-sol";
              variant = "xhigh";
            };
            "coding.md" = {
              model = "openai/gpt-5.6-terra";
              variant = "high";
            };
            "project-research.md" = {
              model = "openai/gpt-5.6-terra";
              variant = "high";
            };
            "web-research.md" = {
              model = "openai/gpt-5.6-terra";
              variant = "high";
            };
          };
          expectedOpencodeAgentFileNames = builtins.attrNames
            expectedOpencodeAgentModels;
          opencodeAgentContents = map
            (fileName: builtins.readFile (opencodeAgentDirectory + "/${fileName}"))
            opencodeAgentFileNames;
          opencodeAgentDefinitionsAreExpected = opencodeAgentFileNames
            == expectedOpencodeAgentFileNames;
          opencodeGlobalRulesFileExists =
            builtins.pathExists opencodeGlobalRulesFile;
          opencodeAgentCommonFieldsAreExpected = lib.all
            (content:
              lib.hasInfix "description: " content
              && lib.hasInfix "mode: subagent" content
              && lib.hasInfix "task: deny" content
              && lib.hasInfix "external_directory: deny" content)
            opencodeAgentContents;
          opencodeReadOnlyAgentNames = [
            "code-review.md"
            "project-research.md"
            "web-research.md"
          ];
          opencodeReadOnlyAgentsDenyEdits = lib.all
            (fileName: lib.hasInfix "edit: deny"
              (builtins.readFile (opencodeAgentDirectory + "/${fileName}")))
            opencodeReadOnlyAgentNames;
          opencodeCodingAgentAllowsEdits = lib.hasInfix "edit: allow"
            (builtins.readFile (opencodeAgentDirectory + "/coding.md"));
          opencodeAgentModelsAreExpected = lib.all
            (fileName:
              let
                content = builtins.readFile
                  (opencodeAgentDirectory + "/${fileName}");
                expected = expectedOpencodeAgentModels.${fileName};
              in
              lib.hasInfix "model: ${expected.model}" content
              && lib.hasInfix "variant: ${expected.variant}" content)
            expectedOpencodeAgentFileNames;
          opencodeBasePermissions = opencodeConfig.permission or {};
          opencodeBuildPermissions =
            (((opencodeConfig.agent or {}).build or {}).permission or {});
          expectedOpencodeRmPermissions = {
            "rm *" = "ask";
            "rm -rf /" = "deny";
            "rm -rf /*" = "deny";
            "rm -rf ~*" = "deny";
            "rm -rf $HOME*" = "deny";
            "rm -fr /" = "deny";
            "rm -fr /*" = "deny";
            "rm -fr ~*" = "deny";
            "rm -fr $HOME*" = "deny";
            "rm -r /" = "deny";
            "rm -r /*" = "deny";
            "rm -r ~*" = "deny";
            "rm -r $HOME*" = "deny";
            "rm --recursive /" = "deny";
            "rm --recursive /*" = "deny";
            "rm --recursive ~*" = "deny";
            "rm --recursive $HOME*" = "deny";
          };
          opencodeBashPermissions = opencodeBasePermissions.bash or {};
          opencodeRmPermissionsAreExpected = lib.all
            (pattern: opencodeBashPermissions.${pattern} or null
              == expectedOpencodeRmPermissions.${pattern})
            (builtins.attrNames expectedOpencodeRmPermissions);
          opencodeBuildAllowsReads =
            (opencodeBuildPermissions.read or null) == "allow";
          opencodeBuildAllowsDoomLoops =
            (opencodeBuildPermissions.doom_loop or null) == "allow";
          opencodeBuildAllowsExternalDirectories =
            (opencodeBuildPermissions.external_directory or null) == "allow";
          opencodeBuildPermissionsAreScoped = lib.all
            (permission: !(builtins.hasAttr permission opencodeBasePermissions))
            [ "read" "doom_loop" "external_directory" ];
          opencodeAgentsDoNotDuplicateRmPermissions = lib.all
            (content: !lib.hasInfix "\"rm " content)
            opencodeAgentContents;
          opencodeSkillNames = builtins.attrNames (lib.filterAttrs
            (_: type: type == "directory")
            (builtins.readDir opencodeSkillDirectory));
          expectedOpencodeSkillNames = [ "bun-init" "uv-init" ];
          opencodeSkillDefinitionsAreExpected = lib.all
            (skillName: builtins.elem skillName opencodeSkillNames)
            expectedOpencodeSkillNames;
          opencodeSkillContents = builtins.listToAttrs (map
            (skillName: {
              name = skillName;
              value = builtins.readFile
                (opencodeSkillDirectory + "/${skillName}/SKILL.md");
            })
            opencodeSkillNames);
          opencodeSkillCommonFieldsAreExpected = lib.all
            (skillName:
              let
                content = opencodeSkillContents.${skillName};
              in
              lib.hasInfix "name: ${skillName}" content
              && lib.hasInfix "description: " content
              && lib.hasInfix "compatibility: opencode" content)
            opencodeSkillNames;
          opencodeInitSkillAgentInstructionsAreExpected = lib.all
            (skillName:
              let
                content = opencodeSkillContents.${skillName};
              in
              lib.hasInfix "AGENTS.md" content
              && lib.hasInfix "<!-- ${skillName}:verification:start -->" content
              && lib.hasInfix "<!-- ${skillName}:verification:end -->" content)
            expectedOpencodeSkillNames;
          opencodeSkillVerificationCommandsAreExpected =
            lib.hasInfix "mise exec -- bun run lint"
              opencodeSkillContents.bun-init
            && lib.hasInfix "mise exec -- bun run typecheck"
              opencodeSkillContents.bun-init
            && lib.hasInfix "mise exec -- bun test"
              opencodeSkillContents.bun-init
            && lib.hasInfix "uv run ruff check ."
              opencodeSkillContents.uv-init
            && lib.hasInfix "uv run pyright"
              opencodeSkillContents.uv-init
            && lib.hasInfix "uv run pytest"
              opencodeSkillContents.uv-init;
          opencodeSkillsDoNotUseCodexHooks = lib.all
            (content:
              !lib.hasInfix "hooks.json" content
              && !lib.hasInfix "$HOME/.agents/skills" content
              && !lib.hasInfix "continue:false" content)
            (builtins.attrValues opencodeSkillContents);
          opencodeSkillsAreHomeManagerManaged = lib.all
            (homeConfiguration: lib.all
              (skillName:
                let
                  configFiles = homeConfiguration.config.xdg.configFile;
                  configFile = configFiles.${"opencode/skills/${skillName}"}
                    or null;
                in
                configFile != null
                && configFile.target
                  == ".config/opencode/skills/${skillName}")
              opencodeSkillNames)
            (builtins.attrValues homeConfigurations);
          opencodeProjectConfigIsEnabled = lib.all
            (homeConfiguration:
              !(homeConfiguration.config.home.sessionVariables
                ? OPENCODE_DISABLE_PROJECT_CONFIG))
            (builtins.attrValues homeConfigurations);
        in
        {
          # 複数のHome Configurationを評価する静的検査なので、テストサイズはMediumとする。
          codex-global-rules-medium =
            assert lib.assertMsg codexGlobalRulesFileExists
              "CodexのグローバルAGENTS.mdがありません";
            assert lib.assertMsg codexGlobalRulesAreHomeManagerManaged
              "CodexのグローバルAGENTS.mdが全Home Configurationで管理されていません";
            pkgs.runCommand "codex-global-rules-medium" { } ''
              mkdir -p "$out"
              echo "CodexのグローバルAGENTS.md配置は正常です" > "$out/result"
            '';

          # 複数のローカルファイルを読む静的検査なので、テストサイズはMediumとする。
          opencode-agent-definitions-medium =
            assert lib.assertMsg opencodeGlobalRulesFileExists
              "OpenCodeのグローバルAGENTS.mdがありません";
            assert lib.assertMsg opencodeAgentDefinitionsAreExpected
              "OpenCodeのsubagent定義が期待する4ファイルと一致しません";
            assert lib.assertMsg opencodeAgentCommonFieldsAreExpected
              "OpenCodeのsubagent定義に必須フィールドまたは再委譲禁止がありません";
            assert lib.assertMsg opencodeReadOnlyAgentsDenyEdits
              "OpenCodeの調査・レビュー担当が読み取り専用ではありません";
            assert lib.assertMsg opencodeCodingAgentAllowsEdits
              "OpenCodeのcoding担当に編集権限がありません";
            assert lib.assertMsg opencodeAgentModelsAreExpected
              "OpenCodeのsubagentのモデルまたはvariantが期待値と一致しません";
            assert lib.assertMsg opencodeRmPermissionsAreExpected
              "OpenCodeの共通rm権限が期待値と一致しません";
            assert lib.assertMsg opencodeBuildAllowsReads
              "OpenCodeのmain agentがファイル読み取り時に承認を要求します";
            assert lib.assertMsg opencodeBuildAllowsDoomLoops
              "OpenCodeの同一ツール再実行時に承認を要求します";
            assert lib.assertMsg opencodeBuildAllowsExternalDirectories
              "OpenCodeのmain agentが作業ツリー外へアクセスできません";
            assert lib.assertMsg opencodeBuildPermissionsAreScoped
              "OpenCodeのmain agent用権限がtop-levelへ漏れています";
            assert lib.assertMsg opencodeAgentsDoNotDuplicateRmPermissions
              "OpenCodeのsubagentに共通rm権限が重複しています";
            pkgs.runCommand "opencode-agent-definitions-medium" { } ''
              mkdir -p "$out"
              echo "OpenCodeのsubagent定義と権限は正常です" > "$out/result"
            '';

          # 複数のローカルファイルを読む静的検査なので、テストサイズはMediumとする。
          opencode-skill-definitions-medium =
            assert lib.assertMsg opencodeSkillDefinitionsAreExpected
              "OpenCodeのSkill定義にbun-initまたはuv-initがありません";
            assert lib.assertMsg opencodeSkillCommonFieldsAreExpected
              "OpenCodeのSkill定義に必須フィールドがありません";
            assert lib.assertMsg opencodeInitSkillAgentInstructionsAreExpected
              "OpenCodeの初期化SkillにAGENTS.md検証指示がありません";
            assert lib.assertMsg opencodeSkillVerificationCommandsAreExpected
              "OpenCodeのSkill定義に必要な検証コマンドがありません";
            assert lib.assertMsg opencodeSkillsDoNotUseCodexHooks
              "OpenCodeのSkill定義にCodex hookが残っています";
            assert lib.assertMsg opencodeSkillsAreHomeManagerManaged
              "OpenCodeのSkillがHome Manager管理ではありません";
            assert lib.assertMsg opencodeProjectConfigIsEnabled
              "OpenCodeのproject AGENTS.md読込が無効化されています";
            pkgs.runCommand "opencode-skill-definitions-medium" { } ''
              mkdir -p "$out"
              echo "OpenCodeのSkill定義とproject AGENTS.md連携は正常です" > "$out/result"
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
