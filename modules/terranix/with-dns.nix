{ config' }:
{
  pkgs,
  lib,
  ...
}:
{
  import = [
    { to = "module.dns.hcloud_zone.clan_lol"; id = "clan.lol"; }
    { to = "module.dns.hcloud_zone.thecomputer_co"; id = "thecomputer.co"; }
  ];

  module.dns = {
    source = toString (
      pkgs.linkFarm "dns-module" [
        {
          name = "config.tf.json";
          path = config'.terranix.terranixConfigurations.dns.result.terraformConfiguration;
        }
      ]
    );
    passphrase = lib.tf.ref "var.passphrase";
  };
}
