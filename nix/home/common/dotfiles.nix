{ pkgs, config, lib, ... }:
let
  stores = import ../../lib/stores.nix { inherit pkgs; };
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

  xdg.configFile."opencode/AGENTS.md" = {
    source = ../../../dotfiles/opencode/AGENTS.md;
    force = true;
  };

  xdg.configFile."opencode/oh-my-opencode.json" = {
    source = ../../../dotfiles/opencode/oh-my-opencode.json;
    force = true;
  };

  xdg.configFile."opencode/opencode.json" = {
    source = ../../../dotfiles/opencode/opencode.json;
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
