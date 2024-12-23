{ config, self, ... }:
let
  user = "u366395";
  host = "${user}.your-storagebox.de";
in
# Run this from the hetzner network
# ssh-keyscan -p 23 <host>
# and update known hosts section below
{
  imports = [ self.inputs.clan-core.clanModules.borgbackup ];

  # 100GB storagebox is under the nix-community hetzner account
  clan.borgbackup.destinations.${config.networking.hostName} = {
    repo = "${user}@${host}:/./borgbackup";
    rsh = "ssh -oPort=23 -i ${config.clan.core.facts.services.borgbackup.secret."borgbackup.ssh".path}";
  };

  clan.core.state.system.folders = [
    "/home"
    "/etc"
    "/var"
    "/root"
  ];

  services.borgbackup.jobs.${config.networking.hostName} = {
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

    # Disaster recovery:
    # get the backup passphrase and ssh key from the sops and store them in /tmp
    # $ export BORG_PASSCOMMAND='cat /tmp/hetzner-borgbackup-passphrase'
    # $ export BORG_REPO='u359378@u359378.your-storagebox.de:/./borgbackup'
    # $ export BORG_RSH='ssh -oPort=23 -i /tmp/hetzner-borgbackup-ssh'
    # $ borg list
    # web01-clan-lol-2023-07-21T14:12:22   Fri, 2023-07-21 14:12:27 [539b1037669ffd0d3f50020f439bbe2881b7234910e405eafc333125383351bc]
    # $ borg mount u359378@u359378.your-storagebox.de:/./borgbackup::web01-clan-lol-2023-07-21T14:12:22 /tmp/backup

    # Also enable ssh support in the storagebox web interface.
    # By default the storage box is only accessible from the hetzner network.
    # $ clan facts generate
    # $ clan facts list web01 | jq .borgbackup.ssh.pub | ssh -p23 u359378@u359378.your-storagebox.de install-ssh-key
    preHook = ''
      set -x
    '';

    postHook = ''
      cat > /var/log/telegraf/borgbackup-clan-lol <<EOF
      task,frequency=daily last_run=$(date +%s)i,state="$([[ $exitStatus == 0 ]] && echo ok || echo fail)"
      EOF
    '';
  };

  systemd.services."borgbackup-job-${config.networking.hostName}".serviceConfig.ReadWritePaths = [
    "/var/log/telegraf"
  ];

  programs.ssh.knownHosts = {
    storagebox-ed25519.hostNames = [ "[${host}]:23" ];
    storagebox-ed25519.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";

    storagebox-ecdsa.hostNames = [ "[${host}]:23" ];
    storagebox-ecdsa.publicKey = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";

    storagebox-rsa.hostNames = [ "[${host}]:23" ];
    storagebox-rsa.publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  };
}
