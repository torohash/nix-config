{ pkgs, config, ... }:
let
  stores = import ../lib/stores.nix { inherit pkgs; };
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
  ];

  home.packages = [
    stores.common
    stores.lsp
  ];

  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.opencode/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    profileExtra = ''
      if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      elif [ -r /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      elif [ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      fi
    '';
    initExtra = ''
      if [ -r /etc/skel/.bashrc ]; then
        . /etc/skel/.bashrc
        __SKEL_BASHRC_LOADED=1
      fi

      if [ -f "${pkgs.git}/share/git/contrib/completion/git-prompt.sh" ]; then
        . "${pkgs.git}/share/git/contrib/completion/git-prompt.sh"
      fi

      update_ps1_cmd1() {
        if type __git_ps1 >/dev/null 2>&1; then
          PS1_CMD1="$(__git_ps1 ' (%s)')"
        else
          PS1_CMD1=""
        fi
      }

      case ";''${PROMPT_COMMAND};" in
        *";update_ps1_cmd1;"*)
          ;;
        *)
          if [ -n "$PROMPT_COMMAND" ]; then
            PROMPT_COMMAND="''${PROMPT_COMMAND};update_ps1_cmd1"
          else
            PROMPT_COMMAND="update_ps1_cmd1"
          fi
          ;;
      esac
      PS1='\[\e[38;5;40m\]\u@\h\[\e[0m\]:\[\e[38;5;39m\]\w\[\e[38;5;214m\]''${PS1_CMD1}\[\e[0m\]\$ '
    '';
    bashrcExtra = ''
      if [ -z "''${__SKEL_BASHRC_LOADED:-}" ] && [ -f "$HOME/.bash_aliases" ]; then
        . "$HOME/.bash_aliases"
      fi
      alias clip='xclip -selection clipboard'
    '';
  };

  home.file.".bashrc".force = true;
  home.file.".profile".force = true;
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

  programs.direnv.enable = true;
  programs.direnv.enableBashIntegration = true;
  programs.direnv.nix-direnv.enable = true;

  home.file.".claude/skills" = {
    source = ../../dotfiles/claude/skills;
    recursive = true;
    force = true;
  };

  xdg.configFile."opencode/AGENTS.md" = {
    source = ../../dotfiles/opencode/AGENTS.md;
    force = true;
  };

  xdg.configFile."opencode/oh-my-opencode.json" = {
    source = ../../dotfiles/opencode/oh-my-opencode.json;
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
}
