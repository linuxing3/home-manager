{...}: {
  # Canonical project tools live in flake/devshells.nix.
  # `.envrc` is `use flake`; this file is only for optional `devenv shell`.
  languages.nix.enable = true;
  cachix.pull = ["linuxing3-system-recovery"];
}
