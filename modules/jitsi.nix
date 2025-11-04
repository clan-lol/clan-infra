{
  lib,
  pkgs,
  config,
  self,
  ...
}:
{
  imports = [
    ./acme.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "jitsi-meet-1.0.8043"
  ];

  services.jitsi-meet = {
    enable = true;
    hostName = "jitsi.clan.lol";
    prosody.lockdown = true;
    config = {
      requireDisplayName = true;
      analytics.disabled = true;
      # https://github.com/Lassulus/superconfig/blob/4cb5b9456d6734d5f4b5aa13e18ecbb4bcd6871e/2configs/services/coms/jitsi.nix#L26-L30
      stunServers = [
        { urls = "turn:turn.matrix.org:3478?transport=udp"; }
        { urls = "turn:turn.matrix.org:3478?transport=tcp"; }
      ];
    };
    interfaceConfig = {
      SHOW_JITSI_WATERMARK = false;
      SHOW_WATERMARK_FOR_GUESTS = false;
      GENERATE_ROOMNAMES_ON_WELCOME_PAGE = false;
      DISABLE_PRESENCE_STATUS = true;
    };
  };

  services.jitsi-videobridge.openFirewall = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.prosody.extraPluginPaths =
    let
      prosody-contrib-plugins = pkgs.fetchFromGitHub {
        owner = "jitsi-contrib";
        repo = "prosody-plugins";
        rev = "v20250923";
        sha256 = "sha256-sq33ATYkZWF+ASR4IZbTGrkGWwRT+xpPMuARLSdxoMU=";
      };
    in
    [ "${prosody-contrib-plugins}/event_sync" ];

  # The first argument needs to be a valid domain name (no underscores) and a subdomain
  # of a virtual host configured in prosody (`services.prosody.virtualHosts`).
  # The second argument is the name of the module which should be found in the top level
  # of a plugin directory.
  services.prosody.extraConfig = ''
    Component "event-sync.jitsi.clan.lol" "event_sync_component"
      muc_component = "conference.jitsi.clan.lol"
      breakout_component = "breakout.jitsi.clan.lol"

      api_prefix = "http://127.0.0.1:8228"
  '';

  clan.core.vars.generators."jitsi-presence" = {
    files.envfile = { };
    runtimeInputs = [ pkgs.coreutils ];
    prompts.ACCESS_TOKEN.persist = false;
    script = ''
      echo "ACCESS_TOKEN=$(cat $prompts/ACCESS_TOKEN)" > $out/envfile
    '';
  };

  systemd.services.jitsi-matrix-presence-clan-lol = {
    wantedBy = [ "multi-user.target" ];
    environment = {
      JITSI_ROOMS = "space,space2,standup,clan.lol,nixos,pub";
      JITSI_SERVER = "https://jitsi.clan.lol";
      ROOM_ID = "!_gftm3igPaZl3_fLP63UPbyN8zazJnumz2LmoIo0PBU";
      HOMESERVER_URL = "https://matrix.org";
      USER_ID = "@alertus-maximus:matrix.org";
      LISTEN_ADDRESS = "127.0.0.1:8228";
    };

    serviceConfig = {
      EnvironmentFile = [
        config.clan.core.vars.generators."jitsi-presence".files."envfile".path
      ];
      DynamicUser = true;
      ExecStart =
        lib.getExe
          self.inputs.jitsi-matrix-presence.packages.${pkgs.stdenv.hostPlatform.system}.default;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
