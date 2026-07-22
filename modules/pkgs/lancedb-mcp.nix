{
  lib,
  python3,
  fetchFromGitHub,
  makeWrapper,
  stdenv,
}:

let
  # Extracted Python environment with all dependencies
  pythonEnv = python3.withPackages (ps: with ps; [
    lancedb
    mcp
    pandas
    sentence-transformers
    pydantic
  ]);

  src = fetchFromGitHub {
    owner = "lancedb";
    repo = "lancedb-mcp-server";
    rev = "91a064ed2fac6be42f83dc683335aaa2084b7d56";
    hash = "sha256-vfL8j4boTCNRpcd+bswRBI0I8iWafkkM85TClknwEY4=";
  };
in
stdenv.mkDerivation {
  pname = "lancedb-mcp";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib/lancedb-mcp

    # Copy the Python script
    cp $src/lancedb_mcp.py $out/lib/lancedb-mcp/

    # Create wrapper script
    makeWrapper ${pythonEnv}/bin/python $out/bin/lancedb-mcp \
      --add-flags "$out/lib/lancedb-mcp/lancedb_mcp.py" \
      --set SENTENCE_TRANSFORMERS_HOME "/sources/huggingface"

    runHook postInstall
  '';

  meta = {
    description = "MCP server for LanceDB vector database with semantic memory capabilities";
    homepage = "https://github.com/lancedb/lancedb-mcp-server";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    mainProgram = "lancedb-mcp";
  };
}
