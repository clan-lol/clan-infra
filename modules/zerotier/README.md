# zerotier controller & client config
These modules implement a simple bash based controller (./ctrl.nix) and
the config to join the VPN. External people who want to join just have to copy
./default.nix into their configuration and rebuild switch.

The configured network uses only ipv6 addresses, they are distributed by 6plane.
Which gives every host a /80.
Reference: https://gist.github.com/laduke/fa1e9a68a79d9038ab117ad0ab69927a
