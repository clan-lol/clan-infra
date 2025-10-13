{ config, ... }:
let
  user = "u499466";
  host = "${user}.your-storagebox.de";
  port = 23;

  # Run this from the hetzner network
  # ssh-keyscan -p 23 <host>
  # and update `storagebox-xxx-knowHost` variables
  storagebox-ed25519-knowHost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  storagebox-ecdsa-knowHost = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
  storagebox-rsa-knowHost = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
in
{
  # Manual borgbackup configuration (not using clanModule)
  # 100GB storagebox is under the nix-community hetzner account

  clan.core.state.system.folders = [
    "/home"
    "/var"
    "/root"
  ];

  services.borgbackup.jobs.${config.networking.hostName} = {
    repo = "${user}@${host}:/./borgbackup";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets.hetzner-borgbackup-passphrase.path}";
    };
    environment.BORG_RSH = "ssh -oPort=23 -i ${config.sops.secrets.hetzner-borgbackup-ssh.path}";

    paths = [
      "/home"
      "/var"
      "/root"
    ];

    exclude = [
      "*.pyc"
      "/var/lib/containers"
      "/var/lib/buildbot-worker/"
      "/var/lib/private/gitea-runner/"
      "/root/*/.direnv"
      "/root/*/.cache"
      "/root/*/.cargo"
      "/root/*/.npm"
      "/root/*/.m2"
      "/root/*/.gradle"
      "/root/*/.opam"
      "/home/*/.clangd"
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

    # Disaster recovery:
    # get the backup passphrase and ssh key from the sops and store them in /tmp
    # $ export BORG_PASSCOMMAND='cat /tmp/hetzner-borgbackup-passphrase'
    # $ export BORG_REPO='u359378@u359378.your-storagebox.de:/./borgbackup'
    # $ export BORG_RSH='ssh -oPort=23 -i /tmp/hetzner-borgbackup-ssh'
    # $ borg list
    # web01-clan-lol-2023-07-21T14:12:22   Fri, 2023-07-21 14:12:27 [539b1037669ffd0d3f50020f439bbe2881b7234910e405eafc333125383351bc]
    # $ borg mount u359378@u359378.your-storagebox.de:/./borgbackup::web01-clan-lol-2023-07-21T14:12:22 /tmp/backup

    # Also enable ssh support in the storagebox web interface.
    # By default the storage box is only accessible from the hetzner network, but you can temporarily enable ssh access from the internet.
    # $ sops -d vars/per-machine/web01/secrets.yaml | yq '.borgbackup-ssh' > /tmp/borgbackup-ssh && chmod 600 /tmp/borgbackup-ssh
    # $ sops -d vars/per-machine/web01/secrets.yaml | yq '.borgbackup-ssh-pub' | ssh -p23 u359378@u359378.your-storagebox.de install-ssh-key
    preHook = ''
      set -x
    '';

    postHook = ''
      cat > /var/log/telegraf/borgbackup-clan-lol <<EOF
      task,frequency=daily last_run=$(date +%s)i,state="$([[ $exitStatus == 0 ]] && echo ok || echo fail)"
      EOF
    '';

    startAt = "daily";
    persistentTimer = true;
  };

  systemd.services."borgbackup-job-${config.networking.hostName}".serviceConfig.ReadWritePaths = [
    "/var/log/telegraf"
  ];

  programs.ssh.knownHosts = {
    storagebox-ed25519.hostNames = [ "[${host}]:${toString port}" ];
    storagebox-ed25519.publicKey = storagebox-ed25519-knowHost;

    storagebox-ecdsa.hostNames = [ "[${host}]:${toString port}" ];
    storagebox-ecdsa.publicKey = storagebox-ecdsa-knowHost;

    storagebox-rsa.hostNames = [ "[${host}]:${toString port}" ];
    storagebox-rsa.publicKey = storagebox-rsa-knowHost;
  };
}
