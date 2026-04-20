{ inputs }:
final: prev:
{
  nnn = prev.nnn.override (_oldAttrs: {
    withNerdIcons = true;
  });
}
