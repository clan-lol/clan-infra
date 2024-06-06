{ self, ... }:
{
  imports = [ self.inputs.clan-core.clanModules.matrix-synapse ];
  clan.matrix-synapse.domain = "clan.lol";
}
