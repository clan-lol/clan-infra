{
  self,
  config,
  lib,
  pkgs,
  ...
}:
{
  system.build.deploy = pkgs.writeShellApplication {
    name = "deploy-${config.networking.hostName}";
    runtimeInputs = [ pkgs.jq ];
    text =
      let
        hostname = config.networking.hostName;

        user = config.system.build.targetUser;
        dest = config.system.build.targetHost;
        darwin-rebuild = config.system.build.darwin-rebuild;
      in
      ''
        set -x

        flags=()
        overriddenInputs=()

        while [ $# -gt 0 ]; do
          flag=$1; shift 1
          if [[ $flag == "--override-input" ]]; then
            arg1=$1; shift 1
            arg2=$1; shift 1
            resolved=$(nix flake metadata "$arg2" --json | jq -r '.path')
            flags+=("--override-input" "$arg1" "$resolved")
            overriddenInputs+=("$resolved")
          fi
        done

        if [[ $(hostname) != "${hostname}" || $USER != "${user}" ]]; then
          nix copy --to ssh-ng://${user}@${dest} ${self} "''${overriddenInputs[@]}"
          ssh -t ${user}@${dest} nix run \
            ${self}#darwinConfigurations.${hostname}.config.system.build.darwin-rebuild \
            "''${flags[@]}" \
            switch \
            -- \
            --flake ${self}#${hostname} \
            "''${flags[@]}"

        ${lib.optionalString
          (pkgs.hostPlatform.system == self.darwinConfigurations.${hostname}.pkgs.hostPlatform.system)
          ''
            else
              ${lib.getExe darwin-rebuild} switch --flake ${self}#${hostname} "''${flags[@]}"
          ''
        }
        fi
      '';
  };
}
