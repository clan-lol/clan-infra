{
  pkgs,
  config,
  lib,
  ...
}:
let
  backupUser = lib.filterAttrs (
    name: user: user.isNormalUser && builtins.elem "backup" user.extraGroups
  ) config.users.users;
in
{
  services.samba = {
    enable = true;
    package = pkgs.samba;
    openFirewall = true;
    settings =
      {
        global = {
          security = "user";
          workgroup = "WORKGROUP";
          "server string" = "Storiantor01";
          interfaces = "eth* en*";
          "max log size" = "50";
          "dns proxy" = false;
          "syslog only" = true;
        };
        B4L = {
          comment = "B4L";
          path = "/mnt/hdd/samba/B4L";
          "force group" = "users";
          public = "yes";
          "guest ok" = "no";
          #"only guest" = "yes";
          "create mask" = "0644";
          "directory mask" = "2777";
          writable = "yes";
          browseable = "yes";
          printable = "no";
          "valid users" = "berwn janik arjen w";
        };
      }
      // lib.mapAttrs (user: opts: {
        comment = user;
        path = "/mnt/hdd/samba/${user}";
        "force user" = user;
        "force group" = "users";
        public = "yes";
        "guest ok" = "no";
        #"only guest" = "yes";
        "create mask" = "0644";
        "directory mask" = "2777";
        writable = "yes";
        browseable = "yes";
        printable = "no";
        "valid users" = user;

      }) backupUser;
  };

  # B4L
  users.users.backup.isNormalUser = true;
  users.users.backup.extraGroups = [ "backup" ];
  users.users.arjen.isNormalUser = true;
  users.users.arjen.extraGroups = [ "backup" ];
  users.users.janik.isNormalUser = true;
  users.users.janik.extraGroups = [ "backup" ];
  users.users.berwn.extraGroups = [ "backup" ];

  clan.core.vars.generators = lib.mapAttrs' (
    user: opts:
    lib.nameValuePair "${user}-smb-password" {
      files.password = { };
      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
        mkpasswd
      ];
      script = ''
        xkcdpass --numwords 3 --delimiter - --count 1 > $out/password
      '';
    }
  ) backupUser;

  systemd.services.samba-smbd.postStart = lib.concatMapStrings (user: let
    password = config.clan.core.vars.generators."${user}-smb-password".files.password.path;
  in ''
    mkdir -p /mnt/hdd/samba/${user}
    chown ${user}:users /mnt/hdd/samba/${user}
    # if a password is unchanged, this will error
    (echo $(<${password}); echo $(<${password})) | ${config.services.samba.package}/bin/smbpasswd -s -a ${user}
  '') (lib.attrNames backupUser);

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
    nssmdns4 = true;
    # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
    enable = true;
    openFirewall = true;
  };
}
