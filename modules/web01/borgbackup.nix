{ config, ... }: {
  # 100GB storagebox is under the nix-community hetzner account

  # $ nix run nixpkgs#xkcdpass -- -d '-' -n 3 -C capitalize "$@"
  sops.secrets.hetzner-borgbackup-ssh = { };
  # $ ssh-keygen -t ed25519 -N "" -f /tmp/ssh_host_ed25519_key
  sops.secrets.hetzner-borgbackup-passphrase = { };

  systemd.services.borgbackup-job-clan-lol.serviceConfig.ReadWritePaths = [
    "/var/log/telegraf"
  ];

  services.borgbackup.jobs.clan-lol = {
    paths = [
      "/home"
      "/var"
      "/root"
    ];
    exclude = [
      "*.pyc"
      "/home/*/.direnv"
      "/home/*/.cache"
      "/home/*/.cargo"
      "/home/*/.npm"
      "/home/*/.m2"
      "/home/*/.gradle"
      "/home/*/.opam"
      "/home/*/.clangd"
      "/var/lib/containerd"
      # already included in database backup
      "/var/lib/postgresql"
      # not so important
      "/var/lib/docker/"
      "/var/log/journal"
      "/var/cache"
      "/var/tmp"
      "/var/log"
    ];
    repo = "u359378@u359378.your-storagebox.de:/./borgbackup";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.sops.secrets.hetzner-borgbackup-passphrase.path}";
    };
    compression = "auto,zstd";
    startAt = "daily";
    environment.BORG_RSH = "ssh -oPort=23 -i ${config.sops.secrets.hetzner-borgbackup-ssh.path}";
    preHook = ''
      set -x
    '';

    postHook = ''
      cat > /var/log/telegraf/borgbackup-clan-lol <<EOF
      task,frequency=daily last_run=$(date +%s)i,state="$([[ $exitStatus == 0 ]] && echo ok || echo fail)"
      EOF
    '';

    prune.keep = {
      within = "1d"; # Keep all archives from the last day
      daily = 7;
      weekly = 4;
      monthly = 0;
    };
  };
}
