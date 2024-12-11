{
  config,
  pkgs,
  self,
  ...
}:

let
  name = "matrix-bot";
in
{
  users.groups.matrix-bot-user = { };
  users.users.matrix-bot-user = {
    group = "matrix-bot-user";
    isSystemUser = true;
    description = "User for matrix-bot service";
    home = "/var/lib/matrix-bot";
    createHome = true;
  };

  systemd.services.${name} = {
    path = [ self.packages.${pkgs.system}.matrix-bot ];
    description = "Matrix bot for changelog and reviews";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      MATRIX_PASSWORD_FILE = "%d/MATRIX_PASSWORD_FILE";
      OPENAI_API_KEY_FILE = "%d/OPENAI_API_KEY_FILE";
      HOME = "/var/lib/${name}";
    };

    serviceConfig = {
      LoadCredential = [
        "MATRIX_PASSWORD_FILE:${config.sops.secrets.web01-matrix-password-clan-bot.path}"
        #"OPENAI_API_KEY_FILE:${config.sops.secrets.qubasas-openai-api-key.path}"
      ];
      User = "matrix-bot-user";
      Group = "matrix-bot-user";
      WorkingDirectory = "/var/lib/${name}";
      RuntimeDirectory = "/var/lib/${name}";
    };

    script = ''
      set -euxo pipefail

      mbot --changelog-room "!FdCwyKsRlfooNYKYzx:matrix.org" --review-room "!tmSRJlbsVXFUKAddiM:gchq.icu" --disable-changelog-bot
    '';
  };
}
