{ config, pkgs, ... }:
{
  services.renovate.enable = true;
  services.renovate.runtimePackages = [
    pkgs.git
    pkgs.openssh
    config.nix.package
    # for Cargo.lock
    pkgs.rustc
    pkgs.cargo
    # for go.mod
    pkgs.go
    pkgs.nodejs
  ];
  services.renovate.settings = {
    labels = [
      "dependencies"
      "renovate"
    ];
    nix.enabled = true;
    lockFileMaintenance.enabled = true;
    automerge = true;
    autodiscover = true;
    autodiscoverTopics = [ "managed-by-renovate" ];
    username = "renovate[bot]";
    gitAuthor = "renovate[bot] <renovate@clan.lol>";
    platform = "gitea";
    endpoint = "https://git.clan.lol/api/v1/";
    onboarding = true;
    #allowedCommands = [
    #  "^tslint --fix$"
    #  "^tslint --[a-z]+$"
    #];
  };
  services.renovate.schedule = "*:0/10";
  services.renovate.package = pkgs.renovate.overrideAttrs (
    {
      patches ? [ ],
      ...
    }:
    {
      patches = patches ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/renovatebot/renovate/pull/33991.diff";
          hash = "sha256-6ME048IiptweOkJhnK9QvQqfJ6QaXWX23SlY5TAmsFE=";
        })
      ];
    }
  );
  services.renovate.credentials.RENOVATE_TOKEN =
    config.clan.core.vars.generators.renovate-token.files.token.path;
  services.renovate.credentials.GITHUB_COM_TOKEN =
    config.clan.core.vars.generators.renovate-github.files.token.path;

  clan.core.vars.generators.renovate-token = {
    prompts.token.type = "hidden";
    prompts.token.persist = true;
    prompts.token.description = "Go to https://git.clan.lol/user/settings/applications and create a new token";
  };

  clan.core.vars.generators.renovate-github = {
    prompts.token.type = "hidden";
    prompts.token.persist = true;
    prompts.token.description = "Go to https://git.clan.lol/user/settings/applications and create a new token";
  };
}
