{
  lib,
  rust-bin,
  makeRustPlatform,
  fetchFromGitHub,
  pkg-config,
  python3,
  openssl,
  zlib,
  libgit2,
}:
(let
  rustPlatform190 = makeRustPlatform {
    cargo = rust-bin.stable."1.90.0".default;
    rustc = rust-bin.stable."1.90.0".default;
  };
in rustPlatform190.buildRustPackage) rec {
  pname = "jcode";
  version = "0.11.15";

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "jcode";
    rev = "v${version}";
    hash = "sha256-XXCjVLHsnFFcqUekauUL5T8nJ8AMH/uSqI4usQGNSOs=";
  };

  cargoHash = "sha256-xsuxiPJyCH3z5dqErc0SKxzAbF9N5GVburXUZP4pPLU=";

  nativeBuildInputs = [ pkg-config python3 ];
  buildInputs = [ openssl zlib libgit2 ];

  postPatch = ''
    # Rust stable compat: replace unstable str::floor_char_boundary usage.
    python - <<'PY'
from pathlib import Path
p = Path('src/tool/mod.rs')
s = p.read_text()
old = '            let kept = &output.output[..output.output.floor_char_boundary(max_chars - 150)];\n'
new = """            let cutoff = max_chars.saturating_sub(150);\n            let safe = output.output\n                .char_indices()\n                .map(|(i, _)| i)\n                .take_while(|&i| i <= cutoff)\n                .last()\n                .unwrap_or(0);\n            let kept = &output.output[..safe];\n"""
if old not in s:
    raise SystemExit('expected snippet not found in src/tool/mod.rs')
p.write_text(s.replace(old, new, 1))
PY
  '';

  doCheck = false;

  meta = with lib; {
    description = "Next generation coding agent harness";
    homepage = "https://github.com/1jehuang/jcode";
    license = licenses.mit;
    mainProgram = "jcode";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
