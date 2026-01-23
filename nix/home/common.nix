{ pkgs, config, ... }:
let
  stores = import ../lib/stores.nix { inherit pkgs; };
in
{
  home.packages = [
    stores.common
  ];

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      lualine-nvim
      bufferline-nvim
      neo-tree-nvim
      plenary-nvim
      nui-nvim
      nvim-treesitter.withAllGrammars
    ];
    extraLuaConfig = ''
      vim.opt.termguicolors = true
      local ok_lualine, lualine = pcall(require, "lualine")
      if ok_lualine then
        lualine.setup()
      end
      local ok_bufferline, bufferline = pcall(require, "bufferline")
      if ok_bufferline then
        bufferline.setup()
      end
    '';
  };

  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.opencode/bin"
  ];

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
    '';
  };

  home.file.".bashrc".force = true;
  home.file.".profile".force = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "torohash";
      email = "123091263+torohash@users.noreply.github.com";
    };
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
}
