{ pkgs, ... }:

{

  home.sessionVariables = {
    RUSTUP_HOME = "/share/data/sources/rustup";
    CARGO_HOME = "/share/data/sources/cargo";
  };

  home.sessionPath = [
    "/share/data/sources/cargo/bin"
  ];

  home.packages = with pkgs; [
      # Rust setup
      rustup
  ];
}
