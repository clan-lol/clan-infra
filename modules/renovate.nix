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
        # https://github.com/renovatebot/renovate/pull/33991
        # https://github.com/SuperSandro2000/renovate/pull/4
        (pkgs.fetchpatch {
          url = "https://github.com/renovatebot/renovate/compare/535874ba60521538cc5e7d7891e2cd6c850a8882...2562d3d04ca14ad7530465a97ef920f4e91a82b9.patch";
          hash = "sha256-h2n0UJKsNM5q4BKAXptCUEJdu5wMkYtVpB1ePAVswr0=";
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
