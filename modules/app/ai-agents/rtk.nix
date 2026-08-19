{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
in {
  home.packages = [
    pkgs.fff-mcp
    pkgs.rtk
  ];

  home.sessionPath = lib.mkAfter [ai.profileBin];

  programs.zsh.initContent = lib.mkAfter ''
    # UOS prepends the Nix profile after .zprofile; restore user-local shims.
    path=("$HOME/.local/bin" "''${path[@]}")
    typeset -U path
    export PATH
  '';

  programs.bash.profileExtra = lib.mkAfter ''
    case ":$PATH:" in
      *:${ai.profileBin}:*) ;;
      *) export PATH=${lib.escapeShellArg ai.profileBin}:$PATH ;;
    esac
  '';

  xdg.configFile."rtk/config.toml".text = ''
    [telemetry]
    enabled = false
    consent_given = false
  '';
}
