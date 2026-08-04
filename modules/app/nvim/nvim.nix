{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home;
  herdrNvim = pkgs.vimUtils.buildVimPlugin {
    pname = "herdr-nvim";
    version = "0.1.1";
    src = pkgs.fetchFromGitHub {
      owner = "ChmaraX";
      repo = "herdr-nvim";
      rev = "9ce76bba554ba022ee622bcf7b04793011728aa2";
      hash = "sha256-szXayf81beA0ti9kx0uQja49+G59Og2bYOze8v+pbik=";
    };
  };
in {
  options.my.features.home.nvim = lib.mkEnableOption "the Home Manager-managed Neovim configuration";

  config = lib.mkIf cfg.nvim {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withPython3 = false;
      withRuby = false;

      extraPackages = with pkgs; [
        fd
        lua-language-server
        markdown-oxide
        nixd
        ripgrep
      ];

      plugins = with pkgs.vimPlugins; [
        auto-dark-mode-nvim
        gitsigns-nvim
        herdrNvim
        lush-nvim
        mini-nvim
        nvim-highlight-colors
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        oil-nvim
        plenary-nvim
        render-markdown-nvim
        telescope-nvim
        todo-comments-nvim
        treesitter-modules-nvim
        zen-mode-nvim
        zenbones-nvim
      ];

      initLua = builtins.readFile ./init.lua;
    };
  };
}
