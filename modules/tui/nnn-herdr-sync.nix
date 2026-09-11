{
  config,
  lib,
  pkgs,
  ...
}: let
  bookmarksDir = "${config.xdg.configHome}/nnn/bookmarks";
  projectsDir = "${config.xdg.configHome}/herdr/plugins/config/cloudmanic.herdr-plus/projects";
  syncNnnHerdrProjects = pkgs.writeShellApplication {
    name = "nnn-herdr-sync";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./sync-nnn-herdr-projects.py} \
        --bookmarks-dir ${lib.escapeShellArg bookmarksDir} \
        --projects-dir ${lib.escapeShellArg projectsDir}
    '';
  };
  nnnHerdrOpen = pkgs.writeShellApplication {
    name = "nnn-herdr-open";
    runtimeInputs = [pkgs.fzf];
    text = ''
      choice="$(
        printf '%s\n' cursor-agent pi codex hx shell \
          | fzf --prompt='command> ' --reverse \
        || true
      )"

      case "$choice" in
        cursor-agent|pi|codex|hx)
          if command -v "$choice" >/dev/null 2>&1; then
            exec "$choice"
          fi
          echo "nnn-herdr-open: $choice not on PATH" >&2
          exec "''${SHELL:-bash}"
          ;;
        *)
          exec "''${SHELL:-bash}"
          ;;
      esac
    '';
  };
in {
  home.packages = [syncNnnHerdrProjects nnnHerdrOpen];

  home.activation.nnnHerdrSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg bookmarksDir}
    run ${syncNnnHerdrProjects}/bin/nnn-herdr-sync
  '';

  systemd.user.services.nnn-herdr-sync = {
    Unit.Description = "Synchronize nnn bookmarks with Herdr Plus projects";

    Service = {
      Type = "oneshot";
      ExecStart = "${syncNnnHerdrProjects}/bin/nnn-herdr-sync";
    };
  };

  systemd.user.paths.nnn-herdr-sync = {
    Unit.Description = "Watch nnn bookmarks for Herdr Plus synchronization";

    Path = {
      PathChanged = bookmarksDir;
      Unit = "nnn-herdr-sync.service";
    };

    Install.WantedBy = ["paths.target"];
  };
}
