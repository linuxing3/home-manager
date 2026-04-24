{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  home.packages = [
    inputs.hermes-agent.packages.${pkgs.system}.default
    pkgs.mcp-cli
  ];

  home.activation.mcpCliCodexInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x "${pkgs.mcp-cli}/bin/mcp-cli" ]; then
      ${pkgs.mcp-cli}/bin/mcp-cli install --target codex --prefer-mcp
    fi
  '';
}
