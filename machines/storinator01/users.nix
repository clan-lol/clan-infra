{ config, self, ... }:
{
  imports = [
    ../../modules/ssh-keys.nix
  ];
  users.users = {
    # web01 is the buildHost for storinator01. It copies the system closure over
    # SSH as root, so authorize web01's host key for root here.
    root.openssh.authorizedKeys.keys = [
      self.nixosConfigurations.web01.config.clan.core.vars.generators.openssh.files."ssh.id_ed25519.pub".value
    ];
    matthew = {
      # https://github.com/MatthewCroughan/
      isNormalUser = true;
      extraGroups = [
        "samba"
        "wheel"
      ];
      uid = 2001;
      openssh.authorizedKeys.keys = config.users.ssh-keys.matthew;
    };
    w = {
      isNormalUser = true;
      extraGroups = [
        "samba"
        "wheel"
      ];
      uid = 2002;
      openssh.authorizedKeys.keys = config.users.ssh-keys.w;
    };
    vi = {
      isNormalUser = true;
      extraGroups = [
        "samba"
        "wheel"
      ];
      uid = 2003;
      openssh.authorizedKeys.keys = config.users.ssh-keys.vi;
    };
    janik = {
      isNormalUser = true;
      uid = 2004;
      extraGroups = [ "samba" ];
      openssh.authorizedKeys.keys = config.users.ssh-keys.janik;
    };
  };
}
