_final: prev: {
  dsh = prev.callPackage (
    {
      writeShellApplication,
      git,
      nodejs_24,
      cacert,
      coreutils,
      gnused,
      gnutar,
      gzip,
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
          gnutar
          gzip
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
          dsh_home="''${DSH_HOME:-$HOME/.dsh}"
          rev="''${DSH_REV:-141eb6fef83422698aef7a981029e843e8161534}"
          landlock_pkg="$src/native/landlock-run/packages/linux-arm64"
          export npm_config_update_notifier=false
          export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
          export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"
          # Cordis HMR (watch-only patch reload after web disables module HMR)
          # requires --expose-internals on argv; NODE_OPTIONS rejects that flag.
          case " ''${NODE_OPTIONS:-} " in
            *" --expose-internals "*)
              export NODE_OPTIONS="''${NODE_OPTIONS//--expose-internals/}"
              export NODE_OPTIONS="''${NODE_OPTIONS//  / }"
              ;;
          esac

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
          if [[ ! -d node_modules || ! -f .dsh-build/runtime-ready ]]; then
            pnpm install --ignore-scripts
            pnpm run build
            mkdir -p .dsh-build
            : >.dsh-build/runtime-ready
          fi

          # Landlock launcher binary is gitignored; fetch the published arm64 prebuild.
          if [[ "$(uname -m)" == aarch64 || "$(uname -m)" == arm64 ]]; then
            if [[ ! -x "$landlock_pkg/bin/landlock-run" ]]; then
              tmp="$(mktemp -d)"
              npm pack --pack-destination "$tmp" @deepseek-ai/node-addon-landlock-run-linux-arm64@0.1.1 >/dev/null
              tar -xzf "$tmp"/deepseek-ai-node-addon-landlock-run-linux-arm64-*.tgz -C "$tmp"
              mkdir -p "$landlock_pkg/bin"
              cp -a "$tmp/package/bin/." "$landlock_pkg/bin/"
              chmod +x "$landlock_pkg/bin/"*
              rm -rf "$tmp"
            fi
          fi

          # Cordis Loader resolves dynamically created bare imports from
          # vendor/loader (not the profile dir). Hoist the profile module
          # fallback into the checkout root so tsx can see them.
          hoist_marker="$src/node_modules/@deepseek-ai/dsh-client-ui-directory-picker-native"
          if [[ ! -e "$hoist_marker" ]]; then
            node --import tsx/esm apps/cli/src/bin.ts --profile web --dump-config >/dev/null
            mkdir -p "$src/node_modules/@deepseek-ai"
            if [[ -d "$dsh_home/profiles/node_modules/@deepseek-ai" ]]; then
              for link in "$dsh_home"/profiles/node_modules/@deepseek-ai/*; do
                [[ -e "$link" ]] || continue
                ln -sfn "$(readlink -f -- "$link")" \
                  "$src/node_modules/@deepseek-ai/$(basename -- "$link")"
              done
            fi
          fi

          exec node --expose-internals --import tsx/esm apps/cli/src/bin.ts "$@"
        '';
      }
  ) {};
}
