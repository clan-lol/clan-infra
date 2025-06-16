{
  pkgs,
  ...
}:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama;
    host = "0.0.0.0";
    port = 11434;
  };

  # Open firewall for Ollama API
  networking.firewall.allowedTCPPorts = [ 11434 ];

  # Optional: Enable GPU acceleration if available
  # hardware.nvidia.modesetting.enable = true;
  # systemd.services.ollama.environment = {
  #   CUDA_VISIBLE_DEVICES = "0";
  # };
}
