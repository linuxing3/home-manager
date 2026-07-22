{lib, ...}: {
  imports = [
    ./packages.nix
    ./theme.nix
    ./program.nix
  ];

  # --- Module option surface ------------------------------------------------
  options.home.nixvim = {
    enable = lib.mkEnableOption "enable nixvim in home-manager";
  };
}
