{
  lib,
  buildGoModule,
  makeWrapper,
}:
buildGoModule {
  pname = "system-panel";
  version = "0.1.0";
  src = ./system-panel;
  vendorHash = null;
  env.CGO_ENABLED = 0;
  ldflags = ["-s" "-w"];
  nativeBuildInputs = [makeWrapper];
  # systemctl and sudo must be the running system's, not a store copy.
  postInstall = ''
    wrapProgram $out/bin/system-panel \
      --suffix PATH : /run/wrappers/bin:/run/current-system/sw/bin
  '';
  meta = {
    description = "Loopback panel that shows and switches Home Manager user services";
    mainProgram = "system-panel";
    platforms = lib.platforms.linux;
  };
}
