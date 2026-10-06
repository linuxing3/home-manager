# Isvoro HKT A1 WireGuard full-tunnel; PreUp pins endpoint via LAN gateway.
{ pkgs, ... }: {
  networking.wireguard.enable = true;
  networking.firewall.trustedInterfaces = [ "wg0" ];
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.66.66.2/24" ];
    privateKeyFile = "/home/Designers/.config/wireguard/isvoro-client.key";
    # Avoid blackholing UDP to the NAT endpoint when AllowedIPs = 0/0
    preSetup = ''
      EP=103.138.72.79
      GW=$(ip -o -4 route show default | awk '{print $3; exit}')
      IF=$(ip -o -4 route show default | awk '{print $5; exit}')
      ip route replace "$EP/32" via "$GW" dev "$IF"
    '';
    postShutdown = ''
      ip route del 103.138.72.79/32 || true
    '';
    peers = [{
      publicKey = "AMdDWzvPiksyFFVLAGNoNZ9TSmCBGwQL1QFJDp925FM=";
      endpoint = "103.138.72.79:10010";
      allowedIPs = [ "0.0.0.0/0" ];
      persistentKeepalive = 25;
    }];
  };
  environment.systemPackages = with pkgs; [ wireguard-tools ];
}
