{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      libglvnd
      mesa
      # vpl-gpu-rt          # for newer GPUs on NixOS >24.05 or unstable
      # onevpl-intel-gpu  # for newer GPUs on NixOS <= 24.05
      # intel-media-sdk   # for older GPUs
    ];
  };
}
