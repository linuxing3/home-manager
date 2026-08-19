{pkgs, ...}: let
  secretspecBwRun = pkgs.writeShellApplication {
    name = "secretspec-bw-run";
    runtimeInputs = [
      pkgs.bitwarden-cli
      pkgs.coreutils
      pkgs.jq
      pkgs.secretspec
    ];
    text = builtins.readFile ./secretspec-bw-run.sh;
  };
in {
  home.packages = [
    pkgs.bitwarden-cli
    secretspecBwRun
  ];

  xdg.configFile."secretspec/home-config.toml".source =
    ../../../secrets/secretspec.toml;
}
