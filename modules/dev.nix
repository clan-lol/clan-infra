# Mostly used by web01.numtide.com
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.bat
    pkgs.delta
    pkgs.fd
    pkgs.fzf
    pkgs.git
    pkgs.git-absorb
    pkgs.hub
    pkgs.gh
    pkgs.lazygit
    pkgs.ripgrep
    pkgs.tig
    pkgs.tmux
    pkgs.direnv
  ];

  programs.bash = {
    loginShellInit = ''
      # Initialize direnv shell integration
      eval "$(direnv hook bash)"
    '';
  };

  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.theme = "robbyrussell";
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    loginShellInit = ''
      # Initialize direnv shell integration
      eval "$(direnv hook zsh)"

      # if the user do not have a zshrc yet, create it
      if [[ ! -f ~/.zshrc ]]; then
        touch ~/.zshrc
      fi

      if [[ -n "''${commands[fzf-share]}" ]]; then
        FZF_CTRL_R_OPTS=--reverse
        source "$(fzf-share)/key-bindings.zsh"
      fi
    '';
  };

  services.eternal-terminal.enable = true;
  networking.firewall.allowedTCPPorts = [ 2022 ];

  # Enable mosh
  programs.mosh.enable = true;

  users.defaultUserShell = "/run/current-system/sw/bin/zsh";
  users.users.root.shell = "/run/current-system/sw/bin/bash";
}
