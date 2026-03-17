{
  pkgs,
  ...
}:
{
 home.packages = with pkgs; [
    nodejs
    nodePackages.mermaid-cli
  ];

}
