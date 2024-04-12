{ self, ... }:
{
  imports = [ self.inputs.clan-core.clanModules.matrix-synapse ];
  clan.matrix-synapse.enable = true;
  clan.matrix-synapse.domain = "clan.lol";
}
