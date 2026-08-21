{ pkgs, config, lib, ... }:
let
  stores = import ../../lib/stores.nix { inherit pkgs; };
  piPackages = [
    "npm:pi-web-access"
    "npm:pi-lens"
    "npm:@ff-labs/pi-fff"
  ];
  yaziPlugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "e07bf41442a7f6fdd003069f380e1ae469a86211";
    sha256 = "sha256-aC8DUZpzNHEf9MW3tX3XcDYY/mWClAHkw+nZaxDQHp8=";
  };
in
{
  # unfree は再配布や利用形態に制限があるライセンスのパッケージ。
  # Nix は既定で unfree を拒否するため、許可する対象を明示する必要がある。
  # 本プロジェクトではビルド成果物の再配布は行わないため許可する。
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "terraform"
    "obsidian"
    "google-chrome"
    "ticktick"
    "bitwarden-desktop"
  ];

  home.packages = [
    stores.common
    stores.lsp
  ];

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.opencode/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    QT_IM_MODULES = "wayland;fcitx";
    # OpenCodeをClaude Code互換設定と外部skillsから隔離する。
    OPENCODE_DISABLE_CLAUDE_CODE = "true";
    OPENCODE_DISABLE_EXTERNAL_SKILLS = "true";
  };

  home.file.".tmux.conf" = {
    text = ''
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      set -g mode-keys vi
      vim_pattern='(\S+/)?g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?'
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +''${vim_pattern}$'"
      bind-key -n C-h if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
      bind-key -n C-j if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
      bind-key -n C-k if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
      bind-key -n C-l if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

      bind-key -T copy-mode-vi C-h select-pane -L
      bind-key -T copy-mode-vi C-j select-pane -D
      bind-key -T copy-mode-vi C-k select-pane -U
      bind-key -T copy-mode-vi C-l select-pane -R

    '';
    force = true;
  };

  home.file.".claude/skills" = {
    source = ../../../dotfiles/claude/skills;
    recursive = true;
    force = true;
  };

  home.file.".claude/rules" = {
    source = ../../../dotfiles/claude/rules;
    recursive = true;
    force = true;
  };

  home.file.".claude/commands" = {
    source = ../../../dotfiles/claude/commands;
    recursive = true;
    force = true;
  };

  home.file.".claude/agents" = {
    source = ../../../dotfiles/claude/agents;
    recursive = true;
    force = true;
  };

  home.file.".claude/hooks" = {
    source = ../../../dotfiles/claude/hooks;
    recursive = true;
    force = true;
  };

  home.file.".claude/settings.json" = {
    source = ../../../dotfiles/claude/settings.json;
    force = true;
  };

  home.file.".codex/rules/destructive-command.rules" = {
    source = ../../../dotfiles/codex/rules/destructive-command.rules;
    force = true;
  };

  # Codexのグローバル設定を配置する。以後の変更はリポジトリ上の設定ファイルで管理する。
  home.file.".codex/config.toml" = {
    source = ../../../dotfiles/codex/config.toml;
    force = true;
  };

  # Codexのグローバル個人指示を配置する。
  home.file.".codex/AGENTS.md" = {
    source = ../../../dotfiles/codex/AGENTS.md;
    force = true;
  };

  # Codex専用のカスタムサブエージェントを配置する。
  home.file.".codex/agents" = {
    source = ../../../dotfiles/codex/agents;
    recursive = true;
    force = true;
  };

  # Piのグローバル個人指示をCodexから分離して配置する。
  home.file.".pi/agent/AGENTS.md" = {
    source = ../../../dotfiles/pi/AGENTS.md;
    force = true;
  };

  # GPT-5.6 Solの長いコンテキストを有効にするモデル設定を配置する。
  home.file.".pi/agent/models.json" = {
    source = ../../../dotfiles/pi/models.json;
    force = true;
  };

  # Piが更新する設定を残したまま、導入するpackage一覧と自動圧縮の余白を設定する。
  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir="$HOME/.pi/agent"
    settings_file="$settings_dir/settings.json"
    pi_packages='${builtins.toJSON piPackages}'
    ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "$settings_file.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$tmp_file"' EXIT

    if [ -f "$settings_file" ]; then
      ${pkgs.jq}/bin/jq \
        --argjson packages "$pi_packages" \
        '.compaction = ((.compaction // {}) + {"enabled": true, "reserveTokens": 150000})
          | .packages = $packages' \
        "$settings_file" > "$tmp_file"
    else
      ${pkgs.jq}/bin/jq \
        --null-input \
        --argjson packages "$pi_packages" \
        '{
          "compaction": {
            "enabled": true,
            "reserveTokens": 150000
          },
          "packages": $packages
        }' > "$tmp_file"
    fi

    ${pkgs.coreutils}/bin/chmod 0644 "$tmp_file"
    ${pkgs.coreutils}/bin/mv "$tmp_file" "$settings_file"
    trap - EXIT
  '';

  # OpenAIの一時障害・利用枠超過・ネットワーク障害・無効応答時だけ、APIキー不要の検索先へ順番に切り替える。
  home.file.".pi/web-search.json" = {
    source = ../../../dotfiles/pi/web-search.json;
    force = true;
  };

  # OpenCodeの共通権限を配置する。個人用opencode.jsoncは上書きしない。
  xdg.configFile."opencode/opencode.json" = {
    source = ../../../dotfiles/opencode/opencode.json;
    force = true;
  };

  # OpenCodeのグローバル個人指示を配置する。
  xdg.configFile."opencode/AGENTS.md" = {
    source = ../../../dotfiles/opencode/AGENTS.md;
    force = true;
  };

  # OpenCodeのネイティブsubagentを配置する。
  xdg.configFile."opencode/agents" = {
    source = ../../../dotfiles/opencode/agents;
    recursive = true;
    force = true;
  };

  # OpenCode専用のプロジェクト初期化Skillを個別配置する。
  xdg.configFile."opencode/skills/bun-init" = {
    source = ../../../dotfiles/opencode/skills/bun-init;
    recursive = true;
    force = true;
  };

  xdg.configFile."opencode/skills/uv-init" = {
    source = ../../../dotfiles/opencode/skills/uv-init;
    recursive = true;
    force = true;
  };

  # Codex専用ディレクトリへSkillを配置する。
  home.file.".codex/skills/typescript-conventions" = {
    source = ../../../dotfiles/claude/skills/typescript-conventions;
    force = true;
  };

  home.file.".codex/skills/test-sizes" = {
    source = ../../../dotfiles/claude/skills/test-sizes;
    force = true;
  };

  home.file.".codex/skills/domain-value-docs" = {
    source = ../../../dotfiles/claude/skills/domain-value-docs;
    force = true;
  };

  home.file.".codex/skills/bun-init" = {
    source = ../../../dotfiles/codex/skills/bun-init;
    force = true;
  };

  home.file.".codex/skills/uv-init" = {
    source = ../../../dotfiles/codex/skills/uv-init;
    force = true;
  };

  home.file.".codex/skills/design-table" = {
    source = ../../../dotfiles/codex/skills/design-table;
    force = true;
  };

  home.file.".codex/skills/semantic-generation" = {
    source = ../../../dotfiles/codex/skills/semantic-generation;
    force = true;
  };

  home.file.".codex/skills/delegate-code-changes" = {
    source = ../../../dotfiles/codex/skills/delegate-code-changes;
    force = true;
  };

  home.file.".codex/skills/delegate-research" = {
    source = ../../../dotfiles/codex/skills/delegate-research;
    force = true;
  };

  home.file.".codex/skills/delegate-code-review" = {
    source = ../../../dotfiles/codex/skills/delegate-code-review;
    force = true;
  };

  xdg.configFile."yazi/yazi.toml" = {
    text = ''
      [opener]
      edit = [
        { run = "nvim %s", block = true, for = "unix" }
      ]

      [[plugin.prepend_fetchers]]
      id = "git"
      url = "*"
      run = "git"

      [[plugin.prepend_fetchers]]
      id = "git"
      url = "*/"
      run = "git"
    '';
  };

  xdg.configFile."yazi/keymap.toml" = {
    text = ''
      [[mgr.prepend_keymap]]
      on = "g"
      run = "shell --block lazygit"
      desc = "Open lazygit"
    '';
  };

  xdg.configFile."yazi/init.lua" = {
    text = ''
      require("git"):setup {
        order = 1500,
      }
    '';
  };

  xdg.configFile."yazi/plugins/git.yazi" = {
    source = "${yaziPlugins}/git.yazi";
    recursive = true;
  };

  xdg.configFile."lazygit/config.yml" = {
    text = ''
      os:
        edit: 'nvim {{filename}}'
        editAtLine: 'nvim +{{line}} {{filename}}'
        editAtLineAndWait: 'nvim +{{line}} {{filename}}'
        editInTerminal: true
    '';
  };

  home.activation.btopThemeTransparency = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    btop_conf="$HOME/.config/btop/btop.conf"
    btop_backup="$HOME/.config/btop/btop.conf.backup"

    mkdir -p "$HOME/.config/btop"

    if [ ! -f "$btop_conf" ] && [ -f "$btop_backup" ]; then
      cp "$btop_backup" "$btop_conf"
    fi

    if [ -f "$btop_conf" ]; then
      if grep -q '^[[:space:]]*theme_background[[:space:]]*=' "$btop_conf"; then
        sed -i 's/^[[:space:]]*theme_background[[:space:]]*=.*/theme_background = false/' "$btop_conf"
      else
        printf '\n# Ghostty の透過背景を活かす\ntheme_background = false\n' >> "$btop_conf"
      fi
    else
      cat > "$btop_conf" <<'EOF'
# Ghostty の透過背景を活かす
theme_background = false
EOF
    fi
  '';
}
