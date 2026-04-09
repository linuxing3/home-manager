{
  config,
  pkgs,
  userSettings,
  ...
}: {
  # --- App launcher frontends ----------------------------------------------
  programs.fuzzel.enable = true;
  programs.fuzzel.package = pkgs.fuzzel;
  programs.fuzzel.settings = {
    main = {
      font = userSettings.font + ":size=20";
      dpi-aware = "no";
      show-actions = "yes";
      terminal = "${pkgs.alacritty}/bin/alacritty";
    };
    colors = {
      background = config.lib.stylix.colors.base00 + "bf";
      text = config.lib.stylix.colors.base07 + "ff";
      match = config.lib.stylix.colors.base05 + "ff";
      selection = config.lib.stylix.colors.base08 + "ff";
      selection-text = config.lib.stylix.colors.base00 + "ff";
      selection-match = config.lib.stylix.colors.base05 + "ff";
      border = config.lib.stylix.colors.base08 + "ff";
    };
    border = {
      width = 3;
      radius = 7;
    };
  };

  programs.wofi.enable = true;
  programs.wofi.settings = {
    hide_scroll = true;
    width = "30%";
    lines = 8;
    line_wrap = "word";
    term = "kitty";
    allow_markup = true;
    always_parse_args = false;
    show_all = true;
    print_command = true;
    layer = "overlay";
    allow_images = true;
    sort_order = "alphabetical";
    gtk_dark = true;
    image_size = 20;
    display_generic = false;
    location = "center";
    key_expand = "Tab";
    insensitive = false;
  };
  programs.wofi.style = ''
    * {
      font-family: JetBrainsMono;
      color: #e5e9f0;
      background: transparent;
    }

    #window {
      background: rgba(41, 46, 66, 0.5);
      margin: auto;
      padding: 10px;
      border-radius: 20px;
      border: 5px solid #b072d1;
    }

    #input {
      padding: 10px;
      margin-bottom: 10px;
      border-radius: 15px;
    }

    #outer-box {
      padding: 20px;
    }

    #img {
      margin-right: 6px;
    }

    #entry {
      padding: 10px;
      border-radius: 15px;
    }

    #entry:selected {
      background-color: #2e3440;
    }

    #text {
      margin: 2px;
    }
  '';

  # services.fnott.enable = true;
  # services.fnott.settings = {
  #   main = {
  #     anchor = "bottom-right";
  #     stacking-order = "top-down";
  #     min-width = 400;
  #     title-font = userSettings.font + ":size=14";
  #     summary-font = userSettings.font + ":size=12";
  #     body-font = userSettings.font + ":size=11";
  #     border-size = 0;
  #   };
  #   low = {
  #     background = config.lib.stylix.colors.base00 + "e6";
  #     title-color = config.lib.stylix.colors.base03 + "ff";
  #     summary-color = config.lib.stylix.colors.base03 + "ff";
  #     body-color = config.lib.stylix.colors.base03 + "ff";
  #     idle-timeout = 150;
  #     max-timeout = 30;
  #     default-timeout = 8;
  #   };
  #   normal = {
  #     background = config.lib.stylix.colors.base00 + "e6";
  #     title-color = config.lib.stylix.colors.base07 + "ff";
  #     summary-color = config.lib.stylix.colors.base07 + "ff";
  #     body-color = config.lib.stylix.colors.base07 + "ff";
  #     idle-timeout = 150;
  #     max-timeout = 30;
  #     default-timeout = 8;
  #   };
  #   critical = {
  #     background = config.lib.stylix.colors.base00 + "e6";
  #     title-color = config.lib.stylix.colors.base08 + "ff";
  #     summary-color = config.lib.stylix.colors.base08 + "ff";
  #     body-color = config.lib.stylix.colors.base08 + "ff";
  #     idle-timeout = 0;
  #     max-timeout = 0;
  #     default-timeout = 0;
  #   };
  # };
}
