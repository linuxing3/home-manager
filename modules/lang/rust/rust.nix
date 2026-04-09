{ config, pkgs, ... }:

{

  home.sessionVariables = {
    RUSTUP_HOME = "/share/data/sources/rustup";
    CARGO_HOME = "/share/data/sources/cargo";
    CARGO_TARGET_DIR = "${config.home.homeDirectory}/.cache/omx-explore-target";
  };

  home.sessionPath = [
    "/share/data/sources/cargo/bin"
  ];

  home.packages = with pkgs; [
      # Rust setup
      rustup
  ];
}
