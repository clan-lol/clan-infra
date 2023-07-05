{ self, ... }:
let
  nixosVars = builtins.fromJSON (builtins.readFile ./nixos-vars.json);
in
{
  imports = [
    self.nixosModules.web01
    self.nixosModules.hcloud
  ];
  sops.defaultSopsFile = ./secrets.yaml;
  users.users.root.openssh.authorizedKeys.keys = nixosVars.ssh_keys;
  system.stateVersion = "23.05";
}
