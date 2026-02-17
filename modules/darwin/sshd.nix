{ config, pkgs, ... }:
{
  clan.core.vars.generators.openssh = {
    files."ssh.id_ed25519" = { };
    files."ssh.id_ed25519.pub".secret = false;
    migrateFact = "openssh";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
    ];
    script = ''
      ssh-keygen -t ed25519 -N "" -f "$out"/ssh.id_ed25519
    '';
  };

  services.openssh.hostKeys = [
    {
      type = "ed25519";
      inherit (config.clan.core.vars.generators.openssh.files."ssh.id_ed25519") path;
    }
  ];
}
