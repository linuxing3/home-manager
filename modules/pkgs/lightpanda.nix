{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  zlib,
  curl,
  cacert,
}: let
  version = "0.2.8";
  src =
    if stdenv.hostPlatform.system == "x86_64-linux"
    then
      fetchurl {
        url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda-x86_64-linux";
        hash = "sha256-jjpeBM9QhpmZCnigqGhuozmJEs2Ykf2pBRNCm4kjAwA=";
      }
    else if stdenv.hostPlatform.system == "aarch64-linux"
    then
      fetchurl {
        url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda-aarch64-linux";
        hash = "sha256-n1TyzDGw2t2Ge6BuzOWfiqWfeHY5R5jpeIKupoC1rRk=";
      }
    else throw "lightpanda: unsupported system ${stdenv.hostPlatform.system}";
in
  stdenv.mkDerivation {
    pname = "lightpanda";
    inherit version src;

    dontUnpack = true;

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      stdenv.cc.cc
      zlib
      curl
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      install -m755 $src $out/bin/lightpanda

      wrapProgram $out/bin/lightpanda \
        --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
        --set CURL_CA_BUNDLE ${cacert}/etc/ssl/certs/ca-bundle.crt

      runHook postInstall
    '';

    meta = with lib; {
      description = "Lightpanda headless browser";
      homepage = "https://github.com/lightpanda-io/browser";
      license = licenses.asl20;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "lightpanda";
    };
  }
