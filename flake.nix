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
      hostModule = platform:
        ./nix/home/hosts + "/${homeUsername}_${platform}.nix";
      mkHomeConfiguration = platform:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${homeSystem};
          extraSpecialArgs = {
            inherit nixgl;
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
          agentDirectory = ./dotfiles/codex/agents;
          skillDirectory = ./dotfiles/codex/skills;
          codexConfig = builtins.fromTOML (builtins.readFile ./dotfiles/codex/config.toml);
          codexMultiAgentV2 = (codexConfig.features or {}).multi_agent_v2 or {};
          roleExpectations = {
            code-change-advanced = {
              model = "gpt-5.6-sol";
              modelReasoningEffort = "xhigh";
              readOnlyProhibition = null;
              sandboxMode = null;
              skillName = "delegate-code-changes";
            };
            code-change-mechanical = {
              model = "gpt-5.6-luna";
              modelReasoningEffort = "medium";
              readOnlyProhibition = null;
              sandboxMode = null;
              skillName = "delegate-code-changes";
            };
            code-change-standard = {
              model = "gpt-5.6-terra";
              modelReasoningEffort = "high";
              readOnlyProhibition = null;
              sandboxMode = null;
              skillName = "delegate-code-changes";
            };
            code-review = {
              model = "gpt-5.6-sol";
              modelReasoningEffort = "xhigh";
              readOnlyProhibition = "読み取り専用で作業し、ファイルの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-code-review";
            };
            project-research-deep = {
              model = "gpt-5.6-sol";
              modelReasoningEffort = "xhigh";
              readOnlyProhibition = "読み取り専用で作業し、ファイルの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-research";
            };
            project-research-lookup = {
              model = "gpt-5.6-luna";
              modelReasoningEffort = "medium";
              readOnlyProhibition = "読み取り専用で作業し、ファイルの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-research";
            };
            project-research-synthesis = {
              model = "gpt-5.6-terra";
              modelReasoningEffort = "high";
              readOnlyProhibition = "読み取り専用で作業し、ファイルの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-research";
            };
            web-research-deep = {
              model = "gpt-5.6-sol";
              modelReasoningEffort = "xhigh";
              readOnlyProhibition = "読み取り専用で作業し、ローカルファイルや外部データの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-research";
            };
            web-research-lookup = {
              model = "gpt-5.6-luna";
              modelReasoningEffort = "medium";
              readOnlyProhibition = "読み取り専用で作業し、ローカルファイルや外部データの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-research";
            };
            web-research-synthesis = {
              model = "gpt-5.6-terra";
              modelReasoningEffort = "high";
              readOnlyProhibition = "読み取り専用で作業し、ローカルファイルや外部データの作成・変更・削除、コミット、追加のサブエージェント起動を行わない";
              sandboxMode = "read-only";
              skillName = "delegate-research";
            };
          };
          roleNames = builtins.attrNames roleExpectations;
          agentFileNames = builtins.attrNames (lib.filterAttrs
            (fileName: _: lib.hasSuffix ".toml" fileName)
            (builtins.readDir agentDirectory));
          agentDefinitions = map
            (fileName:
              (builtins.fromTOML (builtins.readFile (agentDirectory + "/${fileName}")))
              // { inherit fileName; })
            agentFileNames;
          agentNames = map (definition: definition.name) agentDefinitions;
          requiredStringFields = [
            "name"
            "description"
            "developer_instructions"
            "model"
            "model_reasoning_effort"
          ];
          hasRequiredFields = lib.all
            (definition: lib.all
              (field:
                builtins.hasAttr field definition
                && builtins.isString (builtins.getAttr field definition)
                && builtins.getAttr field definition != "")
              requiredStringFields)
            agentDefinitions;
          namesAreUnique = builtins.length agentNames
            == builtins.length (lib.unique agentNames);
          namesMatchFileNames = lib.all
            (definition: definition.fileName == "${definition.name}.toml")
            agentDefinitions;
          definitionsByName = builtins.listToAttrs (map
            (definition: {
              name = definition.name;
              value = definition;
            })
            agentDefinitions);
          definitionsMatchExpectedRoles = lib.sort builtins.lessThan agentNames
            == roleNames;
          roleConfigurationsMatch = lib.all
            (roleName:
              let
                definition = definitionsByName.${roleName};
                expectation = roleExpectations.${roleName};
              in
              definition.model == expectation.model
              && definition.model_reasoning_effort
              == expectation.modelReasoningEffort
              && (definition.sandbox_mode or null) == expectation.sandboxMode)
            roleNames;
          readOnlyAgentNames = lib.filter
            (roleName: roleExpectations.${roleName}.sandboxMode == "read-only")
            roleNames;
          readOnlyInstructionsAreRestricted = lib.all
            (roleName: lib.hasInfix
              roleExpectations.${roleName}.readOnlyProhibition
              definitionsByName.${roleName}.developer_instructions)
            readOnlyAgentNames;
          skillAgentNames = lib.groupBy
            (roleName: roleExpectations.${roleName}.skillName)
            roleNames;
          skillSelectionListsMatch = lib.all
            (skillName:
              let
                expectedAgentNames = skillAgentNames.${skillName};
                skillContent = builtins.readFile
                  (skillDirectory + "/${skillName}/SKILL.md");
                selectionListPrefix = "選択対象のCodex識別名（許可一覧の唯一の情報源）: ";
                selectionListLines = lib.filter
                  (line: lib.hasPrefix selectionListPrefix line)
                  (lib.splitString "\n" skillContent);
                expectedSelectionList = selectionListPrefix
                  + lib.concatMapStringsSep "," (agentName: "`${agentName}`")
                    expectedAgentNames;
              in
              selectionListLines == [ expectedSelectionList ])
            (builtins.attrNames skillAgentNames);
          multiAgentV2ConfigurationIsExpected =
            (codexMultiAgentV2.hide_spawn_agent_metadata or null) == false
            && (codexMultiAgentV2.tool_namespace or null) == "agents";
        in
        {
          # 複数のローカルファイルを読む静的検査なので、テストサイズはMediumとする。
          codex-agent-definitions-medium =
            assert lib.assertMsg (agentFileNames != [ ])
              "Codexのカスタムエージェント定義がありません";
            assert lib.assertMsg hasRequiredFields
              "Codexのカスタムエージェント定義に必須キーの欠落があります";
            assert lib.assertMsg namesAreUnique
              "Codexのカスタムエージェント名が重複しています";
            assert lib.assertMsg namesMatchFileNames
              "Codexのカスタムエージェント名とファイル名が一致しません";
            assert lib.assertMsg definitionsMatchExpectedRoles
              "Codexの役割期待値とカスタムエージェント定義が一致しません";
            assert lib.assertMsg roleConfigurationsMatch
              "Codexのカスタムエージェントのmodel、推論レベルまたはsandboxが期待値と一致しません";
            assert lib.assertMsg readOnlyInstructionsAreRestricted
              "Codexの調査・レビュー担当の禁止指示が不足しています";
            assert lib.assertMsg skillSelectionListsMatch
              "CodexのSkillの役割一覧とカスタムエージェント定義が一致しません";
            assert lib.assertMsg multiAgentV2ConfigurationIsExpected
              "CodexのMultiAgent V2でカスタムエージェントを選択する回避設定が一致しません";
            pkgs.runCommand "codex-agent-definitions-medium" { } ''
              mkdir -p "$out"
              echo "Codexのカスタムエージェント定義、Skill、MultiAgent V2設定は正常です" > "$out/result"
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
