{
  config,
  lib,
  pkgs,
}: rec {
  homeDir = config.home.homeDirectory;
  configHome = config.xdg.configHome;
  profileBin = "${homeDir}/.nix-profile/bin";

  serviceHardening = {
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectControlGroups = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectSystem = "full";
    RestrictAddressFamilies = [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
    RestrictSUIDSGID = true;
    UMask = "0077";
  };

  activationPreamble = ''
    set -eu

    preserve_once() {
      source=$1
      if [[ -f "$source" && ! -e "$source.hm-bak" ]]; then
        ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$source" "$source.hm-bak"
      fi
    }
  '';

  mergeJsonFile = destination: defaults: ''
    ${pkgs.coreutils}/bin/mkdir -p "$(dirname ${lib.escapeShellArg destination})"
    if [[ ! -e ${lib.escapeShellArg destination} ]]; then
      printf '{}\n' >${lib.escapeShellArg destination}
      ${pkgs.coreutils}/bin/chmod 600 ${lib.escapeShellArg destination}
    fi
    preserve_once ${lib.escapeShellArg destination}
    ${pkgs.jq}/bin/jq --slurpfile defaults ${defaults} '. * $defaults[0]' \
      ${lib.escapeShellArg destination} >${lib.escapeShellArg "${destination}.hm-new"}
    ${pkgs.coreutils}/bin/chmod --reference=${lib.escapeShellArg destination} \
      ${lib.escapeShellArg "${destination}.hm-new"}
    ${pkgs.coreutils}/bin/mv ${lib.escapeShellArg "${destination}.hm-new"} \
      ${lib.escapeShellArg destination}
  '';

  mergeTomlFile = destination: defaults: ''
    if [[ -f ${lib.escapeShellArg destination} ]]; then
      preserve_once ${lib.escapeShellArg destination}
      ${pkgs.yq}/bin/tomlq --toml-output --in-place --slurpfile defaults ${defaults} \
        '. * $defaults[0]' ${lib.escapeShellArg destination}
      ${pkgs.coreutils}/bin/chmod --reference=${lib.escapeShellArg "${destination}.hm-bak"} \
        ${lib.escapeShellArg destination}
    fi
  '';

  mergeYamlFile = destination: defaults: query: ''
    if [[ -f ${lib.escapeShellArg destination} ]]; then
      preserve_once ${lib.escapeShellArg destination}
      ${pkgs.yq}/bin/yq --yaml-output --in-place --slurpfile defaults ${defaults} \
        ${lib.escapeShellArg query} ${lib.escapeShellArg destination}
      ${pkgs.coreutils}/bin/chmod --reference=${lib.escapeShellArg "${destination}.hm-bak"} \
        ${lib.escapeShellArg destination}
    fi
  '';

  ensureAndMergeYamlFile = destination: defaults: query: ''
    ${pkgs.coreutils}/bin/mkdir -p "$(dirname ${lib.escapeShellArg destination})"
    if [[ ! -f ${lib.escapeShellArg destination} ]]; then
      ${pkgs.yq}/bin/yq --yaml-output '.' ${defaults} >${lib.escapeShellArg destination}
      ${pkgs.coreutils}/bin/chmod 600 ${lib.escapeShellArg destination}
    fi
    ${mergeYamlFile destination defaults query}
  '';
}
