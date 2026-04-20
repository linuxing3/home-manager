{
  pkgs,
  inputs,
  ...
}:
{
  home.packages = [
    inputs.hermes-agent.packages.${pkgs.system}.default
  ];
}
