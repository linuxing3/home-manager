{ inputs }:
final: prev:
{
  opencode-desktop = prev.opencode-desktop.overrideAttrs (old: {
    cargoDeps = final.rustPlatform.importCargoLock {
      lockFile = old.src + "/packages/desktop/src-tauri/Cargo.lock";
      outputHashes = {
        "specta-2.0.0-rc.22" = "sha256-YsyOAnXELLKzhNlJ35dHA6KGbs0wTAX/nlQoW8wWyJQ=";
        "tauri-specta-2.0.0-rc.21" = "sha256-n2VJ+B1nVrh6zQoZyfMoctqP+Csh7eVHRXwUQuiQjaQ=";
      };
    };
  });
}
