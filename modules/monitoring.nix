{ config, ... }:
{
  imports = [ ./acme.nix ];

  services.nginx.virtualHosts.${config.networking.fqdn} = {
    enableACME = true;
    forceSSL = true;
    # redirect to Grafana
    locations."= /".return = "302 /grafana/";
  };

  clan.core.vars.generators.grafana-gitea-oauth = {
    prompts.client-id = {
      description = "Client ID of the Grafana OAuth2 application in Gitea";
      persist = true;
    };
    prompts.client-secret = {
      description = "Client secret of the Grafana OAuth2 application in Gitea";
      persist = true;
    };
    files.client-id.secret = false;
    files.client-id.deploy = false;
    files.client-secret.restartUnits = [ "grafana.service" ];
  };

  systemd.services.grafana.serviceConfig.LoadCredential = [
    "gitea-oauth-client-secret:${config.clan.core.vars.generators.grafana-gitea-oauth.files.client-secret.path}"
  ];

  services.grafana.settings."auth.generic_oauth" = {
    enabled = true;
    name = "Gitea";
    client_id = config.clan.core.vars.generators.grafana-gitea-oauth.files.client-id.value;
    client_secret = "$__file{/run/credentials/${config.systemd.services.grafana.name}/gitea-oauth-client-secret}";
    scopes = "openid profile email groups";
    auth_url = "https://git.clan.lol/login/oauth/authorize";
    token_url = "https://git.clan.lol/login/oauth/access_token";
    api_url = "https://git.clan.lol/login/oauth/userinfo";
    use_pkce = true;
    login_attribute_path = "preferred_username";
    groups_attribute_path = "groups";
    allowed_groups = "clan";
    role_attribute_path = "contains(groups[*], 'clan:owners') && 'GrafanaAdmin' || 'Editor'";
    allow_assign_grafana_admin = true;
  };

  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "clan-infra";
      options.path = ../dashboards;
    }
  ];

  # Upstream sets instance_interface_names on every Mimir ring but the querier's,
  # which then probes the nonexistent [eth0 en0] default and crash loops.
  services.mimir.configuration.querier.ring.instance_addr = "127.0.0.1";

  # Mimir's blocks retention and Loki's compactor retention are both off by default.
  services.mimir.configuration.limits.compactor_blocks_retention_period = "180d";

  services.loki.configuration = {
    limits_config.retention_period = "90d";
    compactor = {
      working_directory = "${config.services.loki.dataDir}/compactor";
      retention_enabled = true;
      delete_request_store = "filesystem";
    };
  };
}
