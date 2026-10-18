{
  lib,
  buildGoModule,
  makeWrapper,
  android-tools,
  iproute2,
  microsocks,
  psmisc,
  tinyproxy,
}:
buildGoModule {
  pname = "net-panel";
  version = "0.1.0";
  src = ./net-panel;
  vendorHash = null;
  env.CGO_ENABLED = 0;
  ldflags = ["-s" "-w"];
  nativeBuildInputs = [makeWrapper];
  # systemctl/systemd-run/sudo must match the running system, so they come
  # from the host profile instead of the store.
  postInstall = ''
    wrapProgram $out/bin/net-panel \
      --prefix PATH : ${lib.makeBinPath [android-tools iproute2 microsocks psmisc tinyproxy]} \
      --suffix PATH : /run/wrappers/bin:/run/current-system/sw/bin
  '';
  meta = {
    description = "Loopback web panel for Vivo USB share/hotspot, Isvoro HK WireGuard and 1080/18080 proxies";
    mainProgram = "net-panel";
    platforms = lib.platforms.linux;
  };
}
