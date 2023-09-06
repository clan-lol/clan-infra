let
  admins = builtins.fromJSON (builtins.readFile ../targets/admins/users.json);
in
{
  users.users = {
    mic92 = {
      isNormalUser = true;
      home = "/home/joerg";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1000;
      openssh.authorizedKeys.keys = [ admins.mic92 ];
    };
    lassulus = {
      isNormalUser = true;
      home = "/home/lassulus";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1001;
      openssh.authorizedKeys.keys = [ admins.lassulus ];
    };
    dave = {
      isNormalUser = true;
      home = "/home/dave";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/fish";
      uid = 1002;
      openssh.authorizedKeys.keys = [ admins.dave ];
    };

    root.openssh.authorizedKeys.keys = builtins.attrValues admins;
  };

  security.sudo.wheelNeedsPassword = false;
}
