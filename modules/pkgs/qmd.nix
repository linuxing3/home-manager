{
  lib,
  stdenv,
  stdenvNoCC,
  bun,
  makeBinaryWrapper,
  nodejs,
  nodePackages,
  patchelf,
  python3,
  removeReferencesTo,
  sqlite,
  writableTmpDirAsHomeHook,
  src,
}:
let
  version = "2.0.1";
  nodeModulesHash =
    {
      aarch64-linux = "sha256-dkhYM567Y9efdm9P3QreO3ZQ6lj2SmBYi3iZnnLw+70=";
    }
    .${stdenv.hostPlatform.system} or lib.fakeHash;

  nodeModules = stdenv.mkDerivation {
    pname = "qmd-node_modules";
    inherit version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      nodejs
      nodePackages.node-gyp
      patchelf
      python3
      removeReferencesTo
      writableTmpDirAsHomeHook
    ];

    buildInputs = [ sqlite ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR="$(mktemp -d)"
      export npm_config_nodedir="${nodejs}"
      bun install --omit=dev --ignore-scripts --no-progress

      # better-sqlite3 needs a compiled native addon, but its install hook
      # assumes /usr/bin/env exists. Build it explicitly inside the Nix env.
      pushd node_modules/better-sqlite3
      node-gyp rebuild --release

      addon_tmp="$(mktemp)"
      cp build/Release/better_sqlite3.node "$addon_tmp"
      strip --strip-all "$addon_tmp"
      patchelf --remove-rpath "$addon_tmp"
      rm -rf build
      mkdir -p build/Release
      cp "$addon_tmp" build/Release/better_sqlite3.node
      rm -f "$addon_tmp"
      popd

      rm -rf node_modules/.bin

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R ./node_modules "$out/"
      remove-references-to \
        -t "$out" \
        -t "${nodejs}" \
        -t "${nodePackages.node-gyp}" \
        -t "${stdenv.cc.cc.lib}" \
        -t "${stdenv.cc.libc}" \
        "$out/node_modules/better-sqlite3/build/Release/better_sqlite3.node"

      runHook postInstall
    '';

    # Keep the fixed-output result free of rewritten store references.
    dontFixup = true;

    outputHash = nodeModulesHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
stdenvNoCC.mkDerivation {
  pname = "qmd";
  inherit version src;

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  postPatch = ''
    ${python3}/bin/python3 ${./qmd-status-patch.py}
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/qmd"
    cp -R ./src "$out/lib/qmd/"
    cp ./package.json "$out/lib/qmd/"
    cp ./bun.lock "$out/lib/qmd/"
    ln -s ${nodeModules}/node_modules "$out/lib/qmd/node_modules"

    cat >"$out/bin/qmd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
store_app="$(readlink -f "$script_dir/../lib/qmd")"
store_node_modules="$(readlink -f "$store_app/node_modules")"
cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/qmd/runtime"
store_pkg="$(basename "$(dirname "$(dirname "$store_app")")")"
app_dir="$cache_root/$store_pkg"

prepare_runtime() {
  tmp_dir="$cache_root/.''${store_pkg}.tmp.$$"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir/node_modules"
  cp -R "$store_app/src" "$tmp_dir/src"
  cp "$store_app/package.json" "$tmp_dir/package.json"
  cp "$store_app/bun.lock" "$tmp_dir/bun.lock"
  shopt -s dotglob nullglob
  for entry in "$store_node_modules"/*; do
    base="$(basename "$entry")"
    [[ "$base" == "node-llama-cpp" ]] && continue
    ln -s "$entry" "$tmp_dir/node_modules/$base"
  done
  cp -R "$store_node_modules/node-llama-cpp" "$tmp_dir/node_modules/"
  chmod -R u+w "$tmp_dir/node_modules/node-llama-cpp"
  rm -rf "$app_dir"
  mv "$tmp_dir" "$app_dir"
}

if [[ ! -e "$app_dir/package.json" ]] || [[ ! -d "$app_dir/node_modules/node-llama-cpp" ]]; then
  prepare_runtime
fi

export NODE_LLAMA_CPP_XPACKS_STORE_FOLDER="$cache_root/xpack/store"
export NODE_LLAMA_CPP_XPACKS_CACHE_FOLDER="$cache_root/xpack/cache"
export NODE_LLAMA_CPP_GPU="''${NODE_LLAMA_CPP_GPU:-false}"
export CC="${stdenv.cc}/bin/cc"
export CXX="${stdenv.cc}/bin/c++"
export AR="${stdenv.cc.bintools}/bin/ar"
export NM="${stdenv.cc.bintools}/bin/nm"
export DYLD_LIBRARY_PATH="${sqlite.out}/lib''${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${sqlite.out}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$app_dir/node_modules/cmake-js/bin:${lib.makeBinPath [ bun ]}:$PATH"

exec ${bun}/bin/bun run --prefer-offline --no-install --cwd "$app_dir" "$app_dir/src/cli/qmd.ts" "$@"
EOF
    chmod +x "$out/bin/qmd"

    runHook postInstall
  '';

  meta = {
    description = "On-device search engine for markdown notes, meeting transcripts, and knowledge bases";
    homepage = "https://github.com/tobi/qmd";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "qmd";
  };
}
