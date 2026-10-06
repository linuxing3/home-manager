final: prev: let
  cf = prev.writeShellApplication {
    name = "cf";
    runtimeInputs = [prev.nodejs];
    text = ''
      export NPM_CONFIG_CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/npm"
      exec npx --yes cf@1.0.0-beta.12 "$@"
    '';
  };
in {
  cf-cli = prev.symlinkJoin {
    name = "cf-cli";
    paths = [cf];
    postBuild = ''
      ln -sf cf $out/bin/cloudflare
    '';
  };
}
