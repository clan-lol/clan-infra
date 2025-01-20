{
  config,
  pkgs,
  lib,
  ...
}:
{
  terraform.required_providers.external.source = "hashicorp/external";
  terraform.required_providers.vultr.source = "vultr/vultr";

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

  provider.vultr.api_key = config.data.external.vultr-api-key "result.secret";
}
