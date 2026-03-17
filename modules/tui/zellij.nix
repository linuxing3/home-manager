{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zellij
  ];

  home.file = {
    ".config/zellij" = {
      source = ../../configs/zellij;
      recursive = true;
    };
  };
}
