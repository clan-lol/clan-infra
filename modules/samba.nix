{
  pkgs,
  config,
  lib,
  ...
}:
let
  sambaUser = lib.filterAttrs (
    name: user: user.isNormalUser && builtins.elem "samba" user.extraGroups
  ) config.users.users;

  sharedFolders = {
    B4L.users = [
      "berwn"
      "janik"
      "arjen"
      "w"
      "b4l-service"
    ];
    GLOM.users = [ "berwn" ];
  };
in
{
  services.samba = {
    enable = true;
    package = pkgs.samba;
    openFirewall = true;
    settings = {
      global = {
        security = "user";
        workgroup = "WORKGROUP";
        "server string" = "Storiantor01";
        interfaces = "eth* en*";
        "max log size" = "50";
        "dns proxy" = false;
        "syslog only" = true;
      };
    }
    // lib.mapAttrs (share: opts: {
      path = "/mnt/hdd/samba/${share}";
      comment = share;
      "force user" = share;
      "force group" = share;
      public = "yes";
      "guest ok" = "no";
      #"only guest" = "yes";
      "create mask" = "0640";
      "directory mask" = "0750";
      writable = "yes";
      browseable = "yes";
      printable = "no";
      # TODO
      "valid users" = toString opts.users;
    }) sharedFolders
    // lib.mapAttrs (user: opts: {
      comment = user;
      path = "/mnt/hdd/samba/${user}";
      "force user" = user;
      "force group" = "users";
      public = "yes";
      "guest ok" = "no";
      #"only guest" = "yes";
      "create mask" = "0640";
      "directory mask" = "0750";
      writable = "yes";
      browseable = "yes";
      printable = "no";
      "valid users" = user;

    }) sambaUser;
  };

  users.users = {
    # B4L
    backup.isNormalUser = true;
    backup.extraGroups = [ "samba" ];
    arjen.isNormalUser = true;
    arjen.extraGroups = [ "samba" ];
    janik.isNormalUser = true;
    janik.extraGroups = [ "samba" ];
    berwn.extraGroups = [ "samba" ];

    b4l-service.isNormalUser = true;
    b4l-service.extraGroups = [ "samba" ];
  }
  // lib.mapAttrs (share: opts: {
    isSystemUser = true;
    group = share;
  }) sharedFolders;

  users.groups = lib.mapAttrs (share: opts: { }) sharedFolders;

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
  ) sambaUser;

  systemd.services.samba-smbd.postStart =
    lib.concatMapStrings (
      user:
      let
        password = config.clan.core.vars.generators."${user}-smb-password".files.password.path;
      in
      ''
        mkdir -p /mnt/hdd/samba/${user}
        chown ${user}:users /mnt/hdd/samba/${user}
        # if a password is unchanged, this will error
        (echo $(<${password}); echo $(<${password})) | ${config.services.samba.package}/bin/smbpasswd -s -a ${user}
      ''
    ) (lib.attrNames sambaUser)
    + lib.concatMapStrings (share: ''
      mkdir -p /mnt/hdd/samba/${share}
      chown ${share}:${share} /mnt/hdd/samba/${share}
    '') (lib.attrNames sharedFolders);

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
