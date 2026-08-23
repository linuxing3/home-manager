{...}: {
  # Operator defaults for Crabbox. Secrets stay in env / AWS credential chain /
  # broker login — never in this file.
  xdg.configFile."crabbox/config.yaml".text = ''
    provider: aws
    target: linux
    class: tiny
    serverType: t3.small
    aws:
      region: eu-west-1
    capacity:
      market: spot
      fallback: on-demand-after-120s
      hints: true
  '';

  # Direct AWS profile used by Crabbox (credentials live in ~/.aws/credentials).
  home.sessionVariables = {
    AWS_PROFILE = "crabbox";
    AWS_REGION = "eu-west-1";
    AWS_DEFAULT_REGION = "eu-west-1";
  };

  home.file.".aws/config".text = ''
    [profile crabbox]
    region = eu-west-1
    output = json
  '';

  # Non-nnn Herdr Plus project for the Grok-style persona workspace.
  xdg.configFile."herdr/plugins/config/cloudmanic.herdr-plus/projects/grok-sim.toml".text = ''
    name = "grok-sim"
    description = "Grok-like persona (pi) + Crabbox AWS"
    working_dir = "/share/data/sources/grok-workspace"

    [[tabs]]
    name = "grok-sim"
    command = "./bin/grok-sim"

    [[tabs]]
    name = "shell"
    command = "''${SHELL:-bash}"
  '';
}
