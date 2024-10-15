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
      openssh.authorizedKeys.keys = [
        admins.kenji
        admins.kenji-remote
      ];
    };
    johannes = {
      isNormalUser = true;
      home = "/home/johannes";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1005;
      openssh.authorizedKeys.keys = [ admins.johannes ];
    };
    flokli = {
      isNormalUser = true;
      home = "/home/flokli";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1006;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPTVTXOutUZZjXLB0lUSgeKcSY/8mxKkC0ingGK1whD2 flokli"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP7rdJ1klzK8nx74QQA8jYdFwznM1klLS0C7M5lHiu+IAAAABHNzaDo= flokli 20240617 28772765"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA34k0FVKDGNdJ8uk0Ytbvh6J8v+H86F4t6BXAIoW/7xAAAABHNzaDo= flokli 20240704 14321691"
      ];
    };
    timo = {
      isNormalUser = true;
      home = "/home/timo";
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      uid = 1007;
      openssh.authorizedKeys.keys = [ admins.timo ];
    };

    root.openssh.authorizedKeys.keys = builtins.attrValues admins;
  };

  security.sudo.wheelNeedsPassword = false;
}
