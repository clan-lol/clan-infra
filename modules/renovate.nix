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
        # Using https://github.com/Mic92/dotfiles/blob/52cea06ecfdcc4d2294c826340122a9ca4ac167d/machines/eve/modules/renovate/default.nix#L65-L66
        # as the latest version of https://github.com/renovatebot/renovate/pull/33991 is broken
        # see: https://github.com/renovatebot/renovate/pull/33991#issuecomment-2798990410
        (pkgs.fetchpatch {
          url = "https://github.com/renovatebot/renovate/compare/99bd69cd3d2938d9e9f52ec9e924dc4e57d886ad...91535da48df9afbda587bf1c079cb543d929bd49.patch";
          hash = "sha256-aggafF9YN2HexfMH6Ir8kRJHYxy4vW5Ji0FL2/WzqHM=";
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
