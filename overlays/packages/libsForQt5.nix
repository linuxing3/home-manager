{ inputs }:
final: prev:
{
  libsForQt5 =
    prev.libsForQt5
    // {
      fcitx5-with-addons = prev.qt6Packages.fcitx5-with-addons;
    };
}
