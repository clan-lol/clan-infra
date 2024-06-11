{ self, ... }:
{
  imports = [ self.inputs.clan-core.clanModules.matrix-synapse ];
  clan.matrix-synapse.domain = "clan.lol";

  clan.matrix-synapse.users.admin = { admin = true; };
  clan.matrix-synapse.users.monitoring = {};
}
