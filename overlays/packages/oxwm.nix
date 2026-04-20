{ inputs }:
final: prev:
{
  oxwm = inputs.oxwm.packages.${prev.system}.default;
}
