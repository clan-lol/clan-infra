{ self, ... }:

{
  system.configurationRevision = self.rev or self.dirtyRev or null;

  clan.core.sops.defaultGroups = [ "admins" ];
}
