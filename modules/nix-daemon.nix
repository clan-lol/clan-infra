{
  pkgs,
  self,
  ...
}:
{
  nix.package = self.inputs.nix-1.packages.${pkgs.stdenv.hostPlatform.system}.nix;
}
