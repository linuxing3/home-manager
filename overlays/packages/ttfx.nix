_final: prev: {
  ttfx = prev.callPackage (
    {
      lib,
      rustPlatform,
      fetchFromGitHub,
    }:
      rustPlatform.buildRustPackage {
        pname = "ttfx";
        version = "0.3.2-unstable";

        src = fetchFromGitHub {
          owner = "omacom";
          repo = "ttfx";
          rev = "7203e354498462064b7c0a89375051f65cf2ce99";
          hash = "sha256-bwFjC6ZkZibkgXjoYVH2VuqqeXklGR9kmRl2fTitWBU=";
        };

        cargoHash = "sha256-DNrg12MNqBcQi6yvoJObM1gtE90iGBCxeQ3RwueYCE4=";

        doCheck = false;

        meta = with lib; {
          description = "Terminal text effects — Rust port of terminaltexteffects (TTE)";
          homepage = "https://github.com/omacom/ttfx";
          license = licenses.mit;
          mainProgram = "ttfx";
          platforms = platforms.linux;
        };
      }
  ) {};
}
