{ config, ... }:
{
  imports = [
    ../../modules/ssh-keys.nix
  ];
  users.users = {
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
  };
}
