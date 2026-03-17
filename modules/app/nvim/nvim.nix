{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    neovim-remote
    neovide
    lua-language-server
    vscode-langservers-extracted
    nil
    clang-tools
    gnumake
    cmake
    marksman
    python311Packages.python-lsp-server
    typescript-language-server
    java-language-server
    dockerfile-language-server-nodejs
    docker-compose-language-service
    kotlin-language-server
    bash-language-server
    yaml-language-server
    sqls
    nmap
  ];
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  # home.file.".config/nvim".source = ../../../configs/nvim;
  # home.file.".config/nvim".recursive = true;
  # home.file.".config/nvim/lua".lua = ../../../configs/nvim/lua;
  # home.file.".config/nvim/lua".recursive = true;
}
