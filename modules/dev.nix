{
  _class,
  self,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    self.inputs.nix-index-database."${_class}Modules".nix-index

    (lib.optionalAttrs (_class == "nixos") {
      programs.nix-ld.enable = lib.mkDefault true; # for my sanity

      # 2022 = eternal-terminal
      networking.firewall.allowedTCPPorts = [ 2022 ];

      programs.mosh.enable = true;

      users.defaultUserShell = pkgs.zsh;
    })
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
    pkgs.jujutsu
    pkgs.ranger

    pkgs.kitty.terminfo
    (if _class == "darwin" then pkgs.ghostty-bin.terminfo else pkgs.ghostty.terminfo)
  ];

  programs.nix-index-database.comma.enable = true;

  programs.direnv.enable = true;

  programs.zsh =
    {
      enable = true;
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
    }
    // (lib.optionalAttrs (_class == "nixos") {
      ohMyZsh.enable = true;
      ohMyZsh.theme = "robbyrussell";
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    });

  services.eternal-terminal.enable = true;

  users.users.root.shell = pkgs.bash;
}
