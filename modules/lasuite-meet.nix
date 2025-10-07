{
  config,
  pkgs,
  ...
}:
{
  clan.core.vars.generators.lasuite-meet-livekit =
    { lib, config, ... }:
    {
      options.keyName = lib.mkOption {
        type = lib.types.str;
        default = "lasuite-meet";
      };
      config = {
        files.for-livekit = { };
        files.for-lasuite-meet = { };
        runtimeInputs = [
          pkgs.gawk
          pkgs.livekit
        ];
        script = ''
          key=$(livekit-server generate-keys | awk 'NR==2 {print $3}')
          printf '%s: %s' ${lib.escapeShellArg config.keyName} $key > $out/for-livekit
          printf 'LIVEKIT_API_SECRET="%s"' $key > $out/for-lasuite-meet
        '';
        validation.script = config.script;
      };
    };

  clan.core.vars.generators.lasuite-meet-oidc = {
    prompts.client-id.persist = true;
    files.client-id.secret = false;
    files.client-id.deploy = false;
  };

  services.lasuite-meet = {
    enable = true;
    domain = "meet.clan.lol";

    postgresql.createLocally = true;
    redis.createLocally = true;

    livekit = {
      openFirewall = true;
      keyFile = config.clan.core.vars.generators.lasuite-meet-livekit.files.for-livekit.path;
    };

    settings = {
      OIDC_OP_JWKS_ENDPOINT = "https://git.clan.lol/login/oauth/keys";
      OIDC_OP_AUTHORIZATION_ENDPOINT = "https://git.clan.lol/login/oauth/authorize";
      OIDC_OP_TOKEN_ENDPOINT = "https://git.clan.lol/login/oauth/access_token";
      OIDC_OP_USER_ENDPOINT = "https://git.clan.lol/login/oauth/userinfo";
      OIDC_RP_CLIENT_ID = config.clan.core.vars.generators.lasuite-meet-oidc.files.client-id.value;
      OIDC_RP_SCOPES = "openid email profile";
      OIDC_USE_PKCE = true;
      OIDC_REDIRECT_REQUIRE_HTTPS = true;

      LOGIN_REDIRECT_URL = "https://${config.services.lasuite-meet.domain}/";
      LOGIN_REDIRECT_URL_FAILURE = "https://${config.services.lasuite-meet.domain}/";
      LOGOUT_REDIRECT_URL = "https://${config.services.lasuite-meet.domain}/";

      LIVEKIT_API_URL = "https://${config.services.lasuite-meet.domain}/livekit";
      LIVEKIT_API_KEY = config.clan.core.vars.generators.lasuite-meet-livekit.keyName;

      # Necessary for using unauthenticated public meetings
      # https://github.com/suitenumerique/meet/issues/708
      FRONTEND_IS_SILENT_LOGIN_ENABLED = false;
    };
    environmentFile = config.clan.core.vars.generators.lasuite-meet-livekit.files.for-lasuite-meet.path;
  };

  services.nginx.virtualHosts."meet.clan.lol" = {
    enableACME = true;
    forceSSL = true;
  };

  services.postgresql.package = pkgs.postgresql_17;
}
