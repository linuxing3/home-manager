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

  programs.zsh.initContent = lib.mkAfter ''
    # UOS rewrites PATH after .zprofile. Keep Nix profile ahead of
    # ~/.local/bin so Cursor Agent (and other) copies cannot shadow HM.
    path=("$HOME/.bin" "$HOME/.nix-profile/bin" "''${path[@]}")
    typeset -U path
    export PATH
  '';

  programs.bash.profileExtra = lib.mkAfter ''
    export PATH="$HOME/.bin":${lib.escapeShellArg ai.profileBin}:"$PATH"
  '';

  xdg.configFile."rtk/config.toml".text = ''
    [telemetry]
    enabled = false
    consent_given = false
  '';
}
