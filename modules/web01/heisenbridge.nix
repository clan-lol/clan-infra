_: {
  # Single-connection Matrix<->IRC bridge for #clan on irc.hackint.org.
  # but doesn't support private IRC DMs
  services.heisenbridge = {
    enable = true;
    homeserver = "http://[::1]:8008";
    owner = "@admin:clan.lol";
  };

  services.matrix-synapse.settings.app_service_config_files = [
    "/var/lib/heisenbridge/registration.yml"
  ];
}
