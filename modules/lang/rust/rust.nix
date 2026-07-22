{ config, lib, pkgs, ... }:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.rust = lib.mkEnableOption "Enable Rust toolchain module";

  config = lib.mkIf cfg.rust {
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
  };
}
