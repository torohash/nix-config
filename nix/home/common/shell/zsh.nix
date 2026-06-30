{ lib, ... }:
let
  # Variables exported by the locked nixGL.nix wrappers, plus compatible Vulkan
  # and EGL names seen in newer loader stacks.
  nixGLPathVariables = [
    "LD_LIBRARY_PATH"
    "LIBGL_DRIVERS_PATH"
    "LIBVA_DRIVERS_PATH"
    "GBM_BACKENDS_PATH"
    "__EGL_VENDOR_LIBRARY_FILENAMES"
    "__EGL_VENDOR_LIBRARY_DIRS"
    "VK_ICD_FILENAMES"
    "VK_DRIVER_FILES"
    "VK_LAYER_PATH"
  ];

  nixGLSignalVariables = builtins.filter (var: var != "LD_LIBRARY_PATH") nixGLPathVariables;

  nixGLPrimeVariables = [
    "DRI_PRIME"
    "__GLX_VENDOR_LIBRARY_NAME"
    "__NV_PRIME_RENDER_OFFLOAD"
    "__NV_PRIME_RENDER_OFFLOAD_PROVIDER"
    "__VK_LAYER_NV_optimus"
  ];

  zshArray = vars: lib.concatMapStringsSep " " lib.escapeShellArg vars;
in
{
  programs.zsh.initContent = lib.mkBefore ''
    # nixGL wraps GUI applications by exporting GPU loader paths.  When a
    # wrapped terminal starts zsh, those paths would otherwise leak to host
    # applications launched from the shell (for example Flatpak apps).
    typeset -ga __hm_nixgl_signal_vars=( ${zshArray nixGLSignalVariables} )
    typeset -ga __hm_nixgl_path_vars=( ${zshArray nixGLPathVariables} )
    typeset -ga __hm_nixgl_prime_vars=( ${zshArray nixGLPrimeVariables} )
    typeset -g __hm_had_nixgl_env=0

    __hm_nixgl_sanitize_colon_var() {
      emulate -L zsh

      local __hm_name="$1"
      if (( ! ''${+parameters[$__hm_name]} )); then
        return 0
      fi

      local __hm_value="''${(P)__hm_name}"
      if [[ -z $__hm_value ]]; then
        unset "$__hm_name"
        return 0
      fi

      local -a __hm_parts __hm_kept
      local __hm_part
      __hm_parts=( "''${(@s.:.)__hm_value}" )
      __hm_kept=()

      for __hm_part in "''${__hm_parts[@]}"; do
        [[ -z $__hm_part ]] && continue
        if [[ $__hm_part == /nix/store/* ]]; then
          typeset -g __hm_had_nixgl_env=1
          continue
        fi
        __hm_kept+=( "$__hm_part" )
      done

      if (( ''${#__hm_kept[@]} )); then
        typeset -gx "$__hm_name=''${(j.:.)__hm_kept}"
      else
        unset "$__hm_name"
      fi
    }

    for __hm_var in "''${__hm_nixgl_signal_vars[@]}"; do
      if (( ''${+parameters[$__hm_var]} )) && [[ "''${(P)__hm_var}" == */nix/store/* ]]; then
        __hm_had_nixgl_env=1
      fi
    done

    for __hm_var in "''${(k)parameters[(I)__EGL_EXTERNAL_PLATFORM_CONFIG_*]}"; do
      if [[ "''${(P)__hm_var}" == */nix/store/* ]]; then
        __hm_had_nixgl_env=1
      fi
    done

    if (( __hm_had_nixgl_env )); then
      for __hm_var in "''${__hm_nixgl_path_vars[@]}"; do
        __hm_nixgl_sanitize_colon_var "$__hm_var"
      done

      for __hm_var in "''${(k)parameters[(I)__EGL_EXTERNAL_PLATFORM_CONFIG_*]}"; do
        __hm_nixgl_sanitize_colon_var "$__hm_var"
      done

      # These are set by Home Manager's nixGL PRIME wrappers rather than by
      # nixGL.nix itself.  Clear them only when nixGL path variables were seen.
      for __hm_var in "''${__hm_nixgl_prime_vars[@]}"; do
        unset "$__hm_var"
      done
    fi

    unset -f __hm_nixgl_sanitize_colon_var
    unset __hm_var __hm_had_nixgl_env __hm_nixgl_signal_vars __hm_nixgl_path_vars __hm_nixgl_prime_vars
  '';
}
