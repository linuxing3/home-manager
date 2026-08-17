{ pkgs, lib, config, inputs, ... }:
let
    llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.system};
in
{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # overlays = import ./overlays;

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    helix
    neovim
    nnn
    lazygit
    ripgrep
    fzf
    direnv
    bitwarden-cli
    cursor-cli
    pi-coding-agent
    rtk
    llm-agents.herdr
    st
    oxwm
  ];

  cachix.pull = [ "linuxing3-system-recovery" ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;
  # languages.c.enable = true;
  languages.nix.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  #scripts.hello.exec = ''
  #  echo hello from $GREET
  #'';

  # https://devenv.sh/basics/
  enterShell = ''
    #hello         # Run scripts directly
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "nix:build".exec = "nix build";
  #   "devenv:enterShell".after = [ "nix:build" ];
  # };

  # https://devenv.sh/tests/
  #enterTest = ''
    #echo "Running tests"
    #git --version | grep --color=auto "${pkgs.git.version}"
  #'';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
