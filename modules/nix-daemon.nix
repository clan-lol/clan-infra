{ self, pkgs, ... }:
{
  nix.package = self.inputs.nix.packages.${pkgs.hostPlatform.system}.nix;
  #nix.settings.use-cgroups = true;
}
