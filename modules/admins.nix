let
  admins = builtins.fromJSON (builtins.readFile ../targets/admins/users.json);
in
{
  users.users = {
    mic92 = {
      isNormalUser = true;
      home = "/home/mic92";
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
    qubasa = {
      isNormalUser = true;
      home = "/home/qubasa";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1003;
      openssh.authorizedKeys.keys = [ admins.qubasa ];
    };
    kenji = {
      isNormalUser = true;
      home = "/home/kenji";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1004;
      openssh.authorizedKeys.keys = [ admins.kenji ];
    };

    root.openssh.authorizedKeys.keys = builtins.attrValues admins;
  };

  security.sudo.wheelNeedsPassword = false;
}
