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
  systemd.services.${name} = {
    path = [ self.packages.${pkgs.system}.matrix-bot ];
    description = "Matrix bot for changelog and reviews";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      MATRIX_PASSWORD_FILE = "%d/MATRIX_PASSWORD_FILE";
      OPENAI_API_KEY_FILE = "%d/OPENAI_API_KEY_FILE";
      HOME = "/run/${name}";
    };

    serviceConfig = {
      LoadCredential = [
        "MATRIX_PASSWORD_FILE:${config.sops.secrets.web01-matrix-password-clan-bot.path}"
        "OPENAI_API_KEY_FILE:${config.sops.secrets.qubasas-openai-api-key.path}"
      ];
      DynamicUser = true;
      RuntimeDirectory = "${name}";
      WorkingDirectory = "/run/${name}";
    };

    script = ''
      set -euxo pipefail

      mbot --changelog-room "\!FdCwyKsRlfooNYKYzx:matrix.org" --review-room "\!tmSRJlbsVXFUKAddiM:gchq.icu"
    '';
  };
}
