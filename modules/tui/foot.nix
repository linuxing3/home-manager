{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/foot" = {
      source = ../../configs/foot;
      recursive = true;
    };
  };

}
