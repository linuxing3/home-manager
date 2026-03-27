{ lib, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../modules/nixos/localization/default.nix
  ];
  boot.isContainer = true;
  networking.hostName = "base";
  system.stateVersion = "25.11";
  environment.systemPackages = with pkgs; [
    cloud-init
  ];

  networking = {
    firewall.enable = true;
    useDHCP = false;
    useNetworkd = false;
    nameservers = lib.mkDefault [ "127.0.0.1" ];
    interfaces = { };
  };

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
      settings.datasource_list = [ "NoCloud" ];
    };

    # dnsmasq gets port 53
    resolved.enable = lib.mkForce false;

    # local DNS resolver on all the LXCs!
    dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        no-resolv = true;
        no-poll = true;
        cache-size = 10000;
        no-negcache = true;
        dns-forward-max = 1500;
        domain-needed = true;
        # needs 127.0.0.1#53 DNS to be provided
        server = [
          "127.0.0.1#5353"
        ];
      };
    };
  };

  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;

}
