{
  config,
  pkgs,
  lib,
  ...
}:

{
  variable.passphrase = { };

  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.hetznerdns.source = "timohirt/hetznerdns";
  terraform.required_providers.vultr.source = "vultr/vultr";

  data.external.hetznerdns-token = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hetznerdns-token)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  data.external.vultr-api-key = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get vultr-api-key)" '{"secret":$secret}'
          '';
        }
      ))
    ];
  };

  provider.hetznerdns.apitoken = config.data.external.hetznerdns-token "result.secret";
  provider.vultr.api_key = config.data.external.vultr-api-key "result.secret";
}
