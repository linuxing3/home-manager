# Mail accounts for Doom Gnus (Gmail + QQ).
# App passwords / authorization codes live in Agenix; authinfo is written after
# agenix.service mounts them.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home;
  accounts = [
    {
      address = "overlabor77@gmail.com";
      secretName = "mail-gmail-overlabor77-pass.age";
      imapHost = "imap.gmail.com";
      imapPort = 993;
      smtpHost = "smtp.gmail.com";
      smtpPort = 465;
    }
    {
      address = "xingwenju@gmail.com";
      secretName = "mail-gmail-xingwenju-pass.age";
      imapHost = "imap.gmail.com";
      imapPort = 993;
      smtpHost = "smtp.gmail.com";
      smtpPort = 465;
    }
    {
      address = "linuxing3@qq.com";
      secretName = "mail-qq-pass.age";
      imapHost = "imap.qq.com";
      imapPort = 993;
      smtpHost = "smtp.qq.com";
      smtpPort = 465;
    }
  ];
  configured = builtins.filter (a: config.age.secrets ? ${a.secretName}) accounts;
  hasAnySecret = configured != [];
  # HM agenix path is literally "${XDG_RUNTIME_DIR}/agenix/<name>" — expand at runtime.
  writeAuthinfo = pkgs.writeShellScript "mail-write-authinfo" ''
    set -euo pipefail
    umask 077
    authinfo="$HOME/.authinfo"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    wrote=0
    ${lib.concatMapStringsSep "\n" (a: ''
        secret="''${XDG_RUNTIME_DIR}/agenix/${a.secretName}"
        if [[ -r "$secret" ]]; then
          pass=$(tr -d '[:space:]' <"$secret")
          if [[ -n "$pass" ]]; then
            printf 'machine %s login %s password %s port %s\n' \
              ${lib.escapeShellArg a.imapHost} \
              ${lib.escapeShellArg a.address} \
              "$pass" \
              ${lib.escapeShellArg (toString a.imapPort)} >>"$tmp"
            printf 'machine %s login %s password %s port %s\n' \
              ${lib.escapeShellArg a.smtpHost} \
              ${lib.escapeShellArg a.address} \
              "$pass" \
              ${lib.escapeShellArg (toString a.smtpPort)} >>"$tmp"
            wrote=1
          else
            echo "mail-authinfo: empty secret; skip ${a.secretName}" >&2
          fi
        else
          echo "mail-authinfo: secret not readable yet: $secret" >&2
        fi
      '')
      accounts}
    if [[ "$wrote" -eq 1 ]]; then
      mv "$tmp" "$authinfo"
      chmod 600 "$authinfo"
      trap - EXIT
    else
      echo "mail-authinfo: no mail secrets materialized; leave ~/.authinfo untouched" >&2
    fi
  '';
in {
  config = lib.mkIf cfg.doomEmacs (
    lib.mkMerge [
      (lib.mkIf hasAnySecret {
        systemd.user.services.gmail-authinfo = {
          Unit = {
            Description = "Write ~/.authinfo for Gnus mail accounts from Agenix";
            After = ["agenix.service"];
            Wants = ["agenix.service"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${writeAuthinfo}";
          };
          Install.WantedBy = ["default.target"];
        };

        home.activation.gmailAuthinfo = lib.hm.dag.entryAfter ["reloadSystemd"] ''
          ${writeAuthinfo} || true
        '';
      })
      (lib.mkIf (!hasAnySecret) {
        home.activation.gmailAuthinfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
          echo "gmailAuthinfo: no mail Agenix secrets configured yet; Gnus will prompt" >&2
        '';
      })
    ]
  );
}
