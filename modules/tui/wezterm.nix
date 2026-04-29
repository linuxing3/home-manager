{ config, inputs, pkgs, lib, ... }:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.wezterm = lib.mkEnableOption "Enable wezterm module";
  config = lib.mkIf cfg.wezterm {
    programs.wezterm = {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "wezterm-wrapped";
        paths = [ inputs.wezterm.packages.${pkgs.system}.default ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/wezterm \
            --set __EGL_VENDOR_LIBRARY_DIRS ${pkgs.mesa}/share/glvnd/egl_vendor.d \
            --set LIBGL_DRIVERS_PATH ${pkgs.mesa}/lib/dri \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.mesa pkgs.libglvnd ]}
        '';
      };
      extraConfig = ''
        local wezterm = require 'wezterm'

        -- Theme configuration
        local function get_appearance()
          if wezterm.gui then
            return wezterm.gui.get_appearance()
          end
          return "Dark"
        end

        local function scheme_for_appearance(appearance)
          if appearance:find("Light") then
            return "Builtin Solarized Light"
          else
            return "Catppuccin Mocha"
          end
        end

        local appearance = get_appearance()
        local current_scheme = scheme_for_appearance(appearance)

        return {
          color_scheme = current_scheme,
          -- Fallback software renderer for environments missing libEGL
          front_end = "Software",
          -- Default key bindings
          keys = {
            -- New tab (Alt-t)
            {
              key = "t",
              mods = "ALT",
              action = wezterm.action.SpawnTab("CurrentPaneDomain"),
            },
            -- Split vertically (Alt-d)
            {
              key = "d",
              mods = "ALT",
              action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" },
            },
            -- Split horizontally (Alt-v)
            {
              key = "v",
              mods = "ALT",
              action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
            },
            -- Next tab (Alt-Shift-l)
            {
              key = "l",
              mods = "ALT|SHIFT",
              action = wezterm.action.ActivateTabRelative(1),
            },
            -- Previous tab (Alt-Shift-h)
            {
              key = "h",
              mods = "ALT|SHIFT",
              action = wezterm.action.ActivateTabRelative(-1),
            },
            -- Next pane (Alt-Tab)
            {
              key = "Tab",
              mods = "ALT",
              action = wezterm.action.ActivatePaneDirection("Next"),
            },
            -- Previous pane (Shift-Tab)
            {
              key = "Tab",
              mods = "SHIFT",
              action = wezterm.action.ActivatePaneDirection("Prev"),
            },
            -- Toggle theme manually (Alt-m)
            {
              key = "m",
              mods = "ALT",
              action = wezterm.action_callback(function(window, pane)
                if current_scheme == "Builtin Solarized Light" then
                  current_scheme = "Catppuccin Mocha"
                else
                  current_scheme = "Builtin Solarized Light"
                end
                window:set_config_overrides({
                  color_scheme = current_scheme
                })
              end),
            },
            -- Close current pane/window (Alt-w)
            {
              key = "w",
              mods = "ALT",
              action = wezterm.action.CloseCurrentPane { confirm = true },
            },
          },
          -- Watch for system appearance changes
          window_background_opacity = 0.95,
          text_background_opacity = 0.95,
          window_frame = {
            active_titlebar_bg = "#1e1e2e",
            inactive_titlebar_bg = "#1e1e2e",
          },
          -- Other default settings
          enable_tab_bar = true,
          hide_tab_bar_if_only_one_tab = false,
          tab_bar_at_bottom = false,
          use_fancy_tab_bar = true,
          window_padding = {
            left = 2,
            right = 2,
            top = 0,
            bottom = 0,
          },
        }
      '';
    };
  };
}
