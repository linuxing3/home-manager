{
  lib,
  stdenv,
  ...
}:
  stdenv.mkDerivation rec {
    pname = "hx-lsp";
    version = "0.2.11";

    src = fetchTarball {
      url = "https://github.com/erasin/hx-lsp/releases/download/${version}/${pname}-${version}-aarch64-linux.tar.xz";
      sha256 = "0yn6m60pwxw2i50q8l4ni670xbvxwiz45pdl9fg34rl1d0pv9gqx";
    };
    installPhase = ''
      mkdir $out $out/bin;
      cp $src/hx-lsp $out/bin/hx-lsp;
      chmod +x $out/bin/hx-lsp;
    '';

    meta = {
      homepage = "https://github.com/erasin/hx-lsp";
      description = "Lsp server for helix";
      license = lib.licenses.mit;
      maintainers = [];
    };
  }
