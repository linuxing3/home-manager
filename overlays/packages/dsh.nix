_final: prev: {
  dsh = prev.callPackage (
    {
      writeShellApplication,
      git,
      nodejs_24,
      cacert,
      coreutils,
      gnused,
      gnumake,
      pkg-config,
      rustc,
      cargo,
      gcc,
      python3,
    }:
      writeShellApplication {
        name = "dsh";
        runtimeInputs = [
          git
          nodejs_24
          cacert
          coreutils
          gnused
          gnumake
          pkg-config
          rustc
          cargo
          gcc
          python3
        ];
        text = ''
          src="''${DSH_SRC:-$HOME/.local/share/deepseek-harness}"
          tools="''${DSH_TOOLS:-$HOME/.local/share/dsh-tools}"
          rev="''${DSH_REV:-141eb6fef83422698aef7a981029e843e8161534}"
          export npm_config_update_notifier=false
          export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
          export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"

          if [[ ! -d "$src/.git" ]]; then
            mkdir -p "$(dirname -- "$src")"
            git init "$src"
            git -C "$src" remote add origin https://github.com/deepseek-ai/deepseek-harness.git
            git -C "$src" fetch --depth 1 origin "$rev"
            git -C "$src" checkout --detach FETCH_HEAD
          fi

          if [[ ! -x "$tools/node_modules/.bin/pnpm" ]]; then
            mkdir -p "$tools"
            npm install --prefix "$tools" pnpm@11.7.0
          fi
          export PATH="$tools/node_modules/.bin:$PATH"

          cd "$src"
          if [[ ! -d node_modules ]]; then
            pnpm install --ignore-scripts
            pnpm run build
          fi

          exec pnpm --dir "$src" dsh "$@"
        '';
      }
  ) {};
}
