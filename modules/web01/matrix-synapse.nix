{ self, ... }:
{
  imports = [ self.inputs.clan-core.clanModules.matrix-synapse ];
  clan.matrix-synapse.domain = "clan.lol";

  clan.matrix-synapse.users.admin = {
    admin = true;
  };
  clan.matrix-synapse.users.monitoring = { };
  clan.matrix-synapse.users.clan-bot = { };

  # Rate limiting settings
  # we need to up this to be able to support matrix bots
  services.matrix-synapse.settings = {
    rc_login = {
      address = {
        per_second = 20;
        burst_count = 200;
      };
      account = {
        per_second = 20;
        burst_count = 200;
      };
      failed_attempts = {
        per_second = 3;
        burst_count = 15;
      };
    };
  };
}
