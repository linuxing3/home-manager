{pkgs, ...}: let
  hx-anywhere = pkgs.writeShellApplication {
    name = "hx-anywhere";
    runtimeInputs = with pkgs; [
      helix
      st
      xclip
      xdotool
    ];
    text = ''
      set -euo pipefail

      # Helix equivalent of vim-anywhere:
      # open a temp buffer, copy on close, refocus the previous window.
      tmp_dir="''${TMPDIR:-/tmp}/hx-anywhere"
      mkdir -p -- "$tmp_dir"
      chmod 700 "$tmp_dir"

      tmp_file="$tmp_dir/doc-$(date +%y%m%d%H%M%S)"
      : >"$tmp_file"
      chmod 600 "$tmp_file"

      previous_window="$(xdotool getactivewindow 2>/dev/null || true)"

      # Title must match the oxwm floating rule for hx-anywhere.
      st -t hx-anywhere -g 100x35 -e hx "$tmp_file"

      xclip -selection clipboard -in <"$tmp_file"

      if [[ -n "$previous_window" ]]; then
        xdotool windowactivate --sync "$previous_window" 2>/dev/null || true
      fi
    '';
  };
in {
  home.packages = [hx-anywhere];
}
