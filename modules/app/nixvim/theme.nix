{
  lib,
  config,
  ...
}: let
  cfg = config.home.nixvim;
  # --- Theme and TUI bridge assets -----------------------------------------
  opencodeThemeConfig = {
    ".config/opencode/themes/oxocarbon.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/theme.json";
        defs = {
          # Oxocarbon dark palette
          base00 = "#161616"; # terminal background
          base01 = "#262626"; # subtle background
          base02 = "#393939"; # selection / hover
          base03 = "#525252"; # comments / muted (unused — see coolGray)
          coolGray = "#6f6f6f"; # IBM Carbon Gray 60 — visible muted text
          base04 = "#dde1e6"; # secondary text
          base05 = "#f2f4f8"; # primary text
          teal = "#08bdba"; # primary accent
          cyan = "#3ddbd9"; # secondary accent
          blue = "#78a9ff"; # keywords / links
          pink = "#ee5396"; # errors / warnings
          lightpink = "#ff7eb6"; # emphases
          green = "#42be65"; # success / added
          violet = "#be95ff"; # types / info
          lightblue = "#82cfff"; # numbers / subtle accent
          darkblue = "#1a1f2e"; # bar/panel background tint
        };
        theme = {
          # agent color cycle: [secondary, accent, success, warning, primary, error, info]
          # build=secondary(green), plan=accent(teal), then success/warning/primary/...
          primary = {
            dark = "blue";
            light = "blue";
          };
          secondary = {
            dark = "green";
            light = "green";
          };
          accent = {
            dark = "teal";
            light = "teal";
          };
          error = {
            dark = "pink";
            light = "pink";
          };
          warning = {
            dark = "lightpink";
            light = "lightpink";
          };
          success = {
            dark = "green";
            light = "green";
          };
          info = {
            dark = "violet";
            light = "violet";
          };
          text = {
            dark = "base04";
            light = "base00";
          };
          textMuted = {
            dark = "coolGray";
            light = "base03";
          };
          background = {
            dark = "base00";
            light = "base05";
          };
          backgroundPanel = {
            dark = "base01";
            light = "base04";
          };
          backgroundElement = {
            dark = "base02";
            light = "base04";
          };
          border = {
            dark = "base02";
            light = "base03";
          };
          borderActive = {
            dark = "teal";
            light = "teal";
          };
          borderSubtle = {
            dark = "base01";
            light = "base04";
          };
          diffAdded = {
            dark = "green";
            light = "green";
          };
          diffRemoved = {
            dark = "pink";
            light = "pink";
          };
          diffContext = {
            dark = "base03";
            light = "base03";
          };
          diffHunkHeader = {
            dark = "base03";
            light = "base03";
          };
          diffHighlightAdded = {
            dark = "green";
            light = "green";
          };
          diffHighlightRemoved = {
            dark = "pink";
            light = "pink";
          };
          diffAddedBg = {
            dark = "base01";
            light = "base04";
          };
          diffRemovedBg = {
            dark = "base01";
            light = "base04";
          };
          diffContextBg = {
            dark = "base00";
            light = "base05";
          };
          diffLineNumber = {
            dark = "base03";
            light = "base03";
          };
          diffAddedLineNumberBg = {
            dark = "base01";
            light = "base04";
          };
          diffRemovedLineNumberBg = {
            dark = "base01";
            light = "base04";
          };
          markdownText = {
            dark = "base05";
            light = "base00";
          };
          markdownHeading = {
            dark = "teal";
            light = "teal";
          };
          markdownLink = {
            dark = "blue";
            light = "blue";
          };
          markdownLinkText = {
            dark = "cyan";
            light = "cyan";
          };
          markdownCode = {
            dark = "green";
            light = "green";
          };
          markdownBlockQuote = {
            dark = "base03";
            light = "base03";
          };
          markdownEmph = {
            dark = "lightpink";
            light = "lightpink";
          };
          markdownStrong = {
            dark = "lightblue";
            light = "lightblue";
          };
          markdownHorizontalRule = {
            dark = "base02";
            light = "base02";
          };
          markdownListItem = {
            dark = "teal";
            light = "teal";
          };
          markdownListEnumeration = {
            dark = "cyan";
            light = "cyan";
          };
          markdownImage = {
            dark = "blue";
            light = "blue";
          };
          markdownImageText = {
            dark = "cyan";
            light = "cyan";
          };
          markdownCodeBlock = {
            dark = "base04";
            light = "base01";
          };
          syntaxComment = {
            dark = "base03";
            light = "base03";
          };
          syntaxKeyword = {
            dark = "blue";
            light = "blue";
          };
          syntaxFunction = {
            dark = "lightpink";
            light = "lightpink";
          };
          syntaxVariable = {
            dark = "base04";
            light = "base01";
          };
          syntaxString = {
            dark = "green";
            light = "green";
          };
          syntaxNumber = {
            dark = "lightblue";
            light = "lightblue";
          };
          syntaxType = {
            dark = "violet";
            light = "violet";
          };
          syntaxOperator = {
            dark = "blue";
            light = "blue";
          };
          syntaxPunctuation = {
            dark = "cyan";
            light = "cyan";
          };
        };
      };
    };
    ".config/opencode/tui.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/tui.json";
        theme = "oxocarbon";
      };
    };
  };
in {
  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge [
      opencodeThemeConfig
    ];
  };
}
