{
  config,
  lib,
  pkgs,
  ...
}:
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
    final: prev: {
      # Remove `version`, `src` and `pnpmDeps` once we have a newer version in Nixpkgs
      version =
        assert lib.versionOlder prev.version "40.0.6";
        "40.0.6+sandro";

      # using it as a patch does not apply over any version that I know of...
      # so let's just use Sandro's branch directly
      src = pkgs.fetchFromGitHub {
        owner = "SuperSandro2000";
        repo = "renovate";
        rev = "d3c715c0285f2d1186dcb2e889e0bda96d093cb6";
        hash = "sha256-dviGWdVtBBD9PvXv5EJDy+s+wT/fcIhKYtO+mCzBD5o=";
      };

      # use `fetchDeps.override` when https://github.com/NixOS/nixpkgs/pull/407784 is merged
      pnpmDeps =
        assert !prev.pnpmDeps ? override;
        pkgs.pnpm_10.fetchDeps {
          inherit (final) pname version src;
          hash = "sha256-v3coZiCgZm2eQDQTFtTdGqqUOXmjMIXuCHqJk1tdFys=";
        };
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
