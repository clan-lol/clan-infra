{ self, ... }:
{
  users.groups.builder = { };

  users.users.builder = {
    isNormalUser = true;
    home = "/var/lib/builder";
    group = "builder";
    openssh.authorizedKeys.keys = [
      self.nixosConfigurations.web01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value
    ];
  };
}
