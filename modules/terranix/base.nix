{
  config,
  pkgs,
  lib,
  ...
}:

{
  variable.passphrase = { };

  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.hcloud.source = "hetznercloud/hcloud";
  terraform.required_providers.vultr.source = "vultr/vultr";

  data.external.hcloud-token = {
    program = [
      (lib.getExe (
        pkgs.writeShellApplication {
          name = "get-clan-secret";
          text = ''
            jq -n --arg secret "$(clan secrets get hcloud-token)" '{"secret":$secret}'
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

  provider.hcloud.token = config.data.external.hcloud-token "result.secret";
  provider.vultr.api_key = config.data.external.vultr-api-key "result.secret";
}
