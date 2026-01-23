{ pkgs, ... }:
{
  programs.home-manager.enable = true;
  xdg.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
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
