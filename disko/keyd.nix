# Same mapping as .codex/skills/configure-caps-escape:
# Caps tap = Escape, Caps hold = Control, Left Ctrl = C-b,
# both Shifts together = Caps Lock. keyd only, not xmodmap/XKB.
{
  lib,
  pkgs,
  ...
}: let
  grantRt = pkgs.writeShellApplication {
    name = "keyd-grant-rt";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      set -eu

      # keyd 2.6+ calls pthread_setschedparam(SCHED_FIFO). Kernels built with
      # CONFIG_RT_GROUP_SCHED deny that in slices whose cpu.rt_runtime_us is 0,
      # even for root. Give system.slice leftover root bandwidth, then this unit
      # a slice of that leftover, before keyd starts.

      cpu_root=/sys/fs/cgroup/cpu
      rt_file=cpu.rt_runtime_us

      [ -e "$cpu_root/$rt_file" ] || exit 0

      root_rt=$(cat "$cpu_root/$rt_file")
      # -1 disables the global RT throttle; the group scheduler is not blocking us.
      if [ "$root_rt" -lt 0 ]; then
        exit 0
      fi

      slice="$cpu_root/system.slice"
      unit="$cpu_root/system.slice/keyd.service"
      slice_need=200000
      unit_need=50000

      write_rt() {
        printf '%s\n' "$2" >"$1"
      }

      if [ -e "$slice/$rt_file" ]; then
        slice_rt=$(cat "$slice/$rt_file")
        if [ "$slice_rt" -lt "$slice_need" ]; then
          delta=$((slice_need - slice_rt))
          new_root=$((root_rt - delta))
          if [ "$new_root" -lt 0 ]; then
            echo "keyd-grant-rt: not enough root RT bandwidth ($root_rt)" >&2
            exit 1
          fi
          write_rt "$cpu_root/$rt_file" "$new_root"
          write_rt "$slice/$rt_file" "$slice_need"
        fi
      fi

      if [ -e "$unit/$rt_file" ]; then
        write_rt "$unit/$rt_file" "$unit_need"
      fi
    '';
  };
in {
  services.keyd.enable = true;
  services.keyd.keyboards.default = {
    ids = ["*"];
    settings = {
      main = {
        capslock = "overload(control, esc)";
        leftcontrol = "macro(C-b)";
      };
      shift = {
        leftshift = "capslock";
        rightshift = "capslock";
      };
    };
  };

  systemd.services.keyd.serviceConfig = {
    LimitRTPRIO = "infinity";
    LimitMEMLOCK = "infinity";
    ProtectControlGroups = lib.mkForce false;
    ExecStartPre = ["+${lib.getExe grantRt}"];
  };

  environment.systemPackages = [pkgs.keyd];
}
