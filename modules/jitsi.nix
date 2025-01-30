{ pkgs, ... }:
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
      breakoutRooms.hideAddRoomButton = false;
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
        rev = "v20230929";
        sha256 = "sha256-1Lmj+ZWqZRRvHVgNDXXEqH2DwhE7TwP0gktjihJCg1g=";
      };
    in
    [ "${prosody-contrib-plugins}/event_sync" ];

  services.prosody.extraModules = [
    "admin_shell"
    "event_sync"
  ];

  services.prosody.extraConfig = ''
    Component "event_sync.pinpox" "event_sync_component"
      muc_component = "conference.jitsi.clan.lol"
      breakout_component = "breakout.jitsi.clan.lol"

      api_prefix = "http://matrixpresence.0cx.de:8228"
  '';
}
