{ pkgs, ... }:
{
  home.packages = with pkgs; [
    playwright
    python3Packages.playwright
    playwright-driver
    playwright-mcp
  ];

  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  };
}
