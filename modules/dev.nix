{
  self,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    self.inputs.nix-index-database.nixosModules.nix-index
  ];

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
    pkgs.nix-output-monitor
    pkgs.ripgrep
    pkgs.tig
    pkgs.tmux
    pkgs.direnv

    # for flokli
    pkgs.kitty.terminfo
    pkgs.ghostty.terminfo
  ];

  programs.nix-ld.enable = lib.mkDefault true; # for my sanity

  programs.nix-index-database.comma.enable = true;

  programs.direnv.enable = true;

  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.theme = "robbyrussell";
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    loginShellInit = ''
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

  programs.mosh.enable = true;

  users.defaultUserShell = pkgs.zsh;
  users.users.root.shell = pkgs.bashInteractive;
}
