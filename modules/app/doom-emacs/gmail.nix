# Mail accounts for Doom Gnus (Gmail + QQ). Passwords are read from Agenix at
# login time by the `agenix-mail' auth-source backend (doomdir/agenix-auth.el);
# this module only removes the plaintext ~/.authinfo that the old
# gmail-authinfo.service wrote.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home;
  removeLegacyAuthinfo = pkgs.writeShellScript "mail-remove-legacy-authinfo" ''
    authinfo="$HOME/.authinfo"
    [[ -e "$authinfo" ]] || exit 0
    # Delete only a file made entirely of the old generated mail lines.
    if ${pkgs.gnugrep}/bin/grep -qvE \
      '^machine (imap|smtp)\.(gmail|qq)\.com login [^ ]+ password [^ ]+ port (993|465)$' \
      "$authinfo"; then
      echo "mail-authinfo: ~/.authinfo has other entries; left in place" >&2
    else
      rm -f "$authinfo"
      echo "mail-authinfo: removed plaintext ~/.authinfo (passwords now read from Agenix)" >&2
    fi
  '';
in {
  config = lib.mkIf cfg.doomEmacs {
    home.activation.removeLegacyAuthinfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${removeLegacyAuthinfo}
    '';
  };
}
