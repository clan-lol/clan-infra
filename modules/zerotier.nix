{
  lib,
  config,
  pkgs,
  ...
}:
let
  memberIds = [
    "e3d6559697" # opnsense router (NewEdge)
    "6688e8091d" # berwn@laptop
    "57042912f0" # Mic92@turingmachine
  ];
in
{
  systemd.services.zerotier-accept-external = {
    wantedBy = [ "multi-user.target" ];
    after = [ "zerotierone.service" ];
    path = [ config.clan.core.clanPkgs.zerotierone ];
    serviceConfig.ExecStart = pkgs.writeShellScript "zerotier-inventory-autoaccept" ''
      ${lib.concatMapStringsSep "\n" (zerotier-id: ''
        ${config.clan.core.clanPkgs.zerotier-members}/bin/zerotier-members allow ${zerotier-id}
      '') memberIds}
    '';
  };
}
